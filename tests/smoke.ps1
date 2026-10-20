$ErrorActionPreference = 'Stop'

$chromePaths = @(
  'C:\Program Files\Google\Chrome\Application\chrome.exe',
  'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
)
$chromePath = $chromePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $chromePath) { throw 'Install Google Chrome or Microsoft Edge to run this browser smoke test.' }

$root = Split-Path -Parent $PSScriptRoot
$profilePath = Join-Path $env:TEMP ('DeutschMate-Smoke-' + [guid]::NewGuid().ToString('N'))
$port = Get-Random -Minimum 20000 -Maximum 45000
$url = ([uri](Join-Path $root 'index.html')).AbsoluteUri
$chrome = $null
$socket = $null
$requestId = 0

function Send-Cdp {
  param([string]$Method, [hashtable]$Params = @{})
  $script:requestId++
  $id = $script:requestId
  $json = @{ id = $id; method = $Method; params = $Params } | ConvertTo-Json -Compress -Depth 20
  $bytes = [Text.Encoding]::UTF8.GetBytes($json)
  $segment = [ArraySegment[byte]]::new($bytes)
  $script:socket.SendAsync($segment, [Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
  do {
    $buffer = New-Object byte[] 65536
    $receiveSegment = [ArraySegment[byte]]::new($buffer)
    $received = $script:socket.ReceiveAsync($receiveSegment, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
    $response = [Text.Encoding]::UTF8.GetString($buffer, 0, $received.Count) | ConvertFrom-Json
  } while ($response.id -ne $id)
  if ($response.error) { throw "Chrome DevTools command failed: $($response.error.message)" }
  return $response
}

function Evaluate {
  param([string]$Expression)
  $reply = Send-Cdp 'Runtime.evaluate' @{ expression = $Expression; awaitPromise = $true; returnByValue = $true }
  if ($reply.result.result.subtype -eq 'error') { throw $reply.result.result.description }
  return $reply.result.result.value
}

function Assert-Equal {
  param($Actual, $Expected, [string]$Message)
  if ($Actual -ne $Expected) { throw "$Message (expected '$Expected', got '$Actual')" }
  Write-Output "PASS: $Message"
}

try {
  $chromeArgs = @('--headless=new', '--no-sandbox', '--disable-gpu', '--disable-extensions', '--disable-background-networking', "--remote-debugging-port=$port", "--user-data-dir=$profilePath", '--no-first-run', 'about:blank')
  $chrome = Start-Process -FilePath $chromePath -ArgumentList $chromeArgs -PassThru -WindowStyle Hidden

  $version = $null
  for ($attempt = 0; $attempt -lt 40 -and -not $version; $attempt++) {
    Start-Sleep -Milliseconds 250
    try { $version = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/version" -TimeoutSec 1 } catch { }
  }
  if (-not $version) { throw 'Chrome DevTools did not start.' }

  $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/list"
  $target = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
  $script:socket = [Net.WebSockets.ClientWebSocket]::new()
  $script:socket.ConnectAsync([uri]$target.webSocketDebuggerUrl, [Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
  Send-Cdp 'Page.enable' @{} | Out-Null
  Send-Cdp 'Runtime.enable' @{} | Out-Null
  Send-Cdp 'Page.navigate' @{ url = $url } | Out-Null
  Start-Sleep -Milliseconds 500

  Assert-Equal (Evaluate 'document.documentElement.lang') 'ar' 'Arabic dashboard loads by default'
  Assert-Equal (Evaluate 'document.getElementById("levelBadge").textContent') 'A1' 'A1 lesson is available'

  Evaluate 'document.getElementById("onboardBtn").click(); true' | Out-Null
  Evaluate 'document.querySelector("#settingsForm [name=name]").value="Layla"; document.querySelector("#settingsForm [name=level]").value="A1"; document.querySelector("#settingsForm [name=weeklyGoal]").value="5"; document.querySelector("#settingsForm").dispatchEvent(new Event("submit",{bubbles:true,cancelable:true})); true' | Out-Null
  Assert-Equal (Evaluate 'JSON.parse(localStorage.getItem("deutschmate:v1")).name') 'Layla' 'Learner preferences are saved locally'
  Assert-Equal (Evaluate 'document.getElementById("weeklyGoalTarget").textContent') ' / 5' 'Selected weekly goal updates the dashboard'

  Evaluate 'document.getElementById("startLesson").click(); true' | Out-Null
  for ($word = 0; $word -lt 4; $word++) { Evaluate 'document.getElementById("nextWord").click(); true' | Out-Null }
  Assert-Equal (Evaluate 'JSON.parse(localStorage.getItem("deutschmate:v1")).lessons') 1 'Completing the lesson records progress'
  Assert-Equal (Evaluate 'JSON.parse(localStorage.getItem("deutschmate:v1")).sessions') 1 'Completing the lesson records a study session'
  Assert-Equal (Evaluate 'document.getElementById("weeklyValue").textContent') '1' 'Weekly progress counts the completed learning session'
  Assert-Equal (Evaluate 'document.getElementById("streakValue").textContent') '1' 'Completing the first study session starts a one-day streak'

  Send-Cdp 'Page.reload' @{ ignoreCache = $true } | Out-Null
  Start-Sleep -Milliseconds 400
  Assert-Equal (Evaluate 'document.getElementById("lessonsValue").textContent') '1' 'Lesson progress survives a page reload'

  Evaluate 'document.querySelector("[data-practice=flashcards]").click(); document.getElementById("reveal").click(); document.getElementById("no").click(); for(let i=0;i<3;i++){document.getElementById("reveal").click();document.getElementById("yes").click()} true' | Out-Null
  Assert-Equal (Evaluate 'Object.keys(JSON.parse(localStorage.getItem("deutschmate:v1")).cardReviews).length') 4 'Vocabulary review outcomes are saved'
  Assert-Equal (Evaluate 'document.getElementById("wordsValue").textContent') '1' 'A missed word stays in the upcoming review queue'
  if (-not (Evaluate 'JSON.parse(localStorage.getItem("deutschmate:v1")).cardReviews["Guten Morgen"].interval===0')) { throw 'A missed word was not rescheduled for review.' }
  Write-Output 'PASS: Missed vocabulary is rescheduled while remembered words receive a longer interval.'
  Evaluate 'document.getElementById("done").click(); document.querySelector("[data-practice=quiz]").click(); true' | Out-Null
  Evaluate 'document.querySelector(".choice[data-answer=wrong]").click(); true' | Out-Null
  if (-not (Evaluate 'document.querySelector("#quizFeedback .feedback").textContent.includes("الإجابة الصحيحة")')) { throw 'An incorrect grammar answer did not receive an explanation.' }
  Write-Output 'PASS: An incorrect grammar answer receives corrective feedback.'
  Evaluate 'document.getElementById("quizNext").click(); document.querySelector(".choice[data-answer=right]").click(); document.getElementById("quizNext").click(); true' | Out-Null
  Assert-Equal (Evaluate 'document.querySelector("#modalContent h2").textContent') 'اكتمل التحدّي!' 'Grammar challenge includes two questions and a completion state'
  if (-not (Evaluate 'document.querySelector("#modalContent p").textContent.includes("1 من 2")')) { throw 'The grammar challenge did not calculate the mixed-answer score correctly.' }
  Write-Output 'PASS: Grammar quiz score reflects one correct answer out of two.'
  Assert-Equal (Evaluate 'JSON.parse(localStorage.getItem("deutschmate:v1")).sessions') 3 'Completed lesson, flashcards, and quiz record three sessions'
  Evaluate 'document.getElementById("quizDone").click(); true' | Out-Null

  Evaluate 'document.getElementById("language").value="en"; document.getElementById("language").dispatchEvent(new Event("change")); true' | Out-Null
  Assert-Equal (Evaluate 'document.documentElement.lang') 'en' 'Interface language can switch to English'
  Evaluate 'document.getElementById("tutorInput").value="When do I use der?"; document.getElementById("tutorForm").dispatchEvent(new Event("submit",{bubbles:true,cancelable:true})); true' | Out-Null
  if (-not (Evaluate 'document.getElementById("chatReply").textContent.includes("grammatical gender")')) { throw 'The local sample tutor did not provide its expected German article explanation.' }
  Write-Output 'PASS: Local tutor responds with a German article explanation.'

  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 1; mobile = $true } | Out-Null
  Assert-Equal (Evaluate 'window.innerWidth') 390 'Mobile viewport is applied in Chrome'
  if (-not (Evaluate 'document.documentElement.scrollWidth <= window.innerWidth + 1')) { throw 'The page overflows horizontally at a 390px viewport.' }
  Write-Output 'PASS: Page has no horizontal overflow at 390px.'
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 320; height = 740; deviceScaleFactor = 1; mobile = $true } | Out-Null
  if (-not (Evaluate 'document.documentElement.scrollWidth <= window.innerWidth + 1')) { throw 'The page overflows horizontally at a 320px viewport.' }
  Write-Output 'PASS: Page has no horizontal overflow at 320px.'

  Evaluate 'localStorage.setItem("deutschmate:v1",JSON.stringify({lang:"ar",level:"B1",lessons:2,sessions:9,streak:7,completed:["greetings"]})); true' | Out-Null
  Send-Cdp 'Page.reload' @{ ignoreCache = $true } | Out-Null
  Start-Sleep -Milliseconds 400
  Assert-Equal (Evaluate 'document.getElementById("lessonsValue").textContent') '2' 'Existing local lesson progress is retained during state migration'
  Assert-Equal (Evaluate 'document.getElementById("streakValue").textContent') '0' 'An old streak without a study date is not shown as current'
}
finally {
  if ($socket) { $socket.Dispose() }
  if ($chrome -and -not $chrome.HasExited) { Stop-Process -Id $chrome.Id -Force -ErrorAction SilentlyContinue }
  if (Test-Path -LiteralPath $profilePath) { Remove-Item -LiteralPath $profilePath -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Output 'All DeutschMate browser smoke checks passed.'
