-- hammerspoon 스크립트: KBU_PUBLIC 네트워크 자동 로그인
-- 네트워크에 연결될 때마다 자동으로 캠퍼스 네트워크 인증을 수행합니다

-- 설정 변수 (사용자 정보 입력 필요)
local ssidTarget = "KBU_PUBLIC"
local portalUrl = "http://192.119.128.3:9997/SubscriberPortal/"
local portalHost = "192.119.128.3"
local username = ""  -- 사용자 계정으로 변경하세요
local password = ""  -- 사용자 비밀번호로 변경하세요

-- 로그인 작업 실행 상태 추적 변수
local isLoginInProgress = false

-- 디버그 로깅 함수: 시간 포맷과 함께 로그 메시지를 출력합니다
local function log(message)
    print(os.date("%Y-%m-%d %H:%M:%S") .. " [KBU_AUTO] " .. message)
end

-- URL 인코딩 함수: HTTP 요청에 사용할 문자열을 적절히 인코딩합니다
local function urlEncode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w %-%_%.%~])",
            function(c) return string.format("%%%02X", string.byte(c)) end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

-- 폼 데이터 인코딩: HTTP POST 요청에 맞게 파라미터를 변환합니다
local function encodeFormData(params)
    local result = {}
    for k, v in pairs(params) do
        table.insert(result, urlEncode(k) .. "=" .. urlEncode(v))
    end
    return table.concat(result, "&")
end

-- 토큰 추출 함수: HTML에서 특정 form 값을 추출합니다
local function extractFormValue(html, name)
    local pattern = 'name="' .. name .. '" value="([^"]+)"'
    return html:match(pattern)
end

-- 인터넷 연결 확인 함수: 로그인 성공 여부를 최종 확인합니다
local function checkInternetConnection()
    hs.http.asyncGet("http://www.google.com", nil, function(status, body, headers)
        if status == 200 then
            log("인터넷 연결 확인됨. KBU_PUBLIC 로그인 및 네트워크 연결 완료!")
            hs.alert.show("[KBU_AUTO] 인터넷 연결 확인 완료!")
            -- 로그인 작업 완료 설정
            isLoginInProgress = false
        else
            log("인터넷 연결 실패. 상태 코드: " .. (status or "nil"))
            log("추가 로그인 시도 중...")
            hs.timer.doAfter(5, function()
                getLoginPageAndTokens()
            end)
        end
    end)
end

-- POST 요청으로 로그인 수행: 획득한 토큰과 쿠키로 인증 요청을 전송합니다
local function performLogin(formTokens, cookies)
    log("로그인 시도 중...")
    
    -- 로그인 폼 파라미터 구성: 포털 요청에 필요한 모든 값을 설정합니다
    local loginParams = {
        ["RequestType"] = "Login",
        ["uip"] = formTokens.uip or "",
        ["wlan"] = "4",
        ["zone"] = "",
        ["thirdPartyZone"] = "",
        ["proxy"] = "0",
        ["url"] = "null",
        ["GuestUser"] = "0",
        ["AuthenticationType"] = "",
        ["LoginFromForm"] = formTokens.LoginFromForm or "",
        ["AppResponseCode"] = "200",
        ["AppErrorMessage"] = "OK",
        ["UE-Username"] = username,
        ["UE-Password"] = password
    }
    
    -- 헤더 설정: 브라우저와 유사한 요청 헤더를 구성합니다
    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36",
        ["Origin"] = "http://192.119.128.3:9997",
        ["Referer"] = "http://192.119.128.3:9997/SubscriberPortal/",
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7",
        ["Cache-Control"] = "no-cache",
        ["Pragma"] = "no-cache",
        ["Upgrade-Insecure-Requests"] = "1",
        ["Connection"] = "keep-alive"
    }
    
    -- 쿠키 설정: 세션 유지에 필요한 쿠키를 설정합니다
    if cookies and #cookies > 0 then
        local cookieStr = table.concat(cookies, "; ")
        headers["Cookie"] = cookieStr
        log("쿠키 설정: " .. cookieStr)
    end
    
    -- 폼 데이터 인코딩
    local encodedData = encodeFormData(loginParams)
    
    -- POST 요청 전송 및 응답 처리
    hs.http.asyncPost(portalUrl, encodedData, headers, function(status, body, responseHeaders)
        if status == 200 or status == 302 then
            log("로그인 요청 응답 수신. 상태 코드: " .. status)
            
            -- 로그인 성공 여부 확인: 응답 내용에서 성공 메시지 검색
            if body and (body:find("User .* is logged in") or body:find("AppResponseCode\" value=\"101\"")) then
                log("로그인 성공 확인됨!")
                hs.alert.show("KBU_PUBLIC 자동로그인 성공!")
                
                -- 인터넷 연결 확인
                hs.timer.doAfter(3, function()
                    checkInternetConnection()
                end)
            else
                log("로그인 응답은 받았으나 성공 확인 불가. 재시도 중...")
                if body then
                    log("응답 내용 일부: " .. string.sub(body, 1, 200) .. "...")
                end
                hs.timer.doAfter(5, function()
                    getLoginPageAndTokens()
                end)
            end
        else
            log("로그인 요청 실패. 상태 코드: " .. status)
            if body then
                log("응답 내용 일부: " .. string.sub(body, 1, 100) .. "...")
            end
            hs.timer.doAfter(5, function()
                getLoginPageAndTokens()
            end)
        end
    end)
end

-- 로그인 페이지 방문 및 토큰 획득: 캡티브 포털에서 필요한 값을 추출합니다
local function getLoginPageAndTokens()
    log("로그인 페이지 방문 및 토큰 획득 중...")
    
    -- 기본 헤더 설정
    local headers = {
        ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36",
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7",
        ["Cache-Control"] = "no-cache",
        ["Pragma"] = "no-cache"
    }
    
    -- 로그인 페이지 GET 요청 및 응답 처리
    hs.http.asyncGet(portalUrl, headers, function(status, body, responseHeaders)
        if status == 200 then
            log("로그인 페이지 로드 성공")
            
            -- 쿠키 추출: 서버에서 설정한 세션 쿠키를 저장합니다
            local cookies = {}
            if responseHeaders["Set-Cookie"] then
                if type(responseHeaders["Set-Cookie"]) == "table" then
                    for _, cookieStr in ipairs(responseHeaders["Set-Cookie"]) do
                        local cookie = cookieStr:match("^([^;]+)")
                        if cookie then
                            table.insert(cookies, cookie)
                        end
                    end
                else
                    local cookie = responseHeaders["Set-Cookie"]:match("^([^;]+)")
                    if cookie then
                        table.insert(cookies, cookie)
                    end
                end
                log("쿠키 추출됨: " .. table.concat(cookies, "; "))
            end
            
            -- 토큰 추출: 로그인에 필요한 동적 값을 HTML에서 파싱합니다
            local formTokens = {
                uip = extractFormValue(body, "uip"),
                LoginFromForm = extractFormValue(body, "LoginFromForm")
            }
            
            if formTokens.uip and formTokens.LoginFromForm then
                log("토큰 추출 성공: uip=" .. formTokens.uip .. ", LoginFromForm=" .. formTokens.LoginFromForm)
                performLogin(formTokens, cookies)
            else
                log("토큰 추출 실패. 재시도 중...")
                hs.timer.doAfter(5, function()
                    getLoginPageAndTokens()
                end)
            end
        else
            log("로그인 페이지 로드 실패. 상태 코드: " .. status)
            hs.timer.doAfter(5, function()
                getLoginPageAndTokens()
            end)
        end
    end)
end

-- 네트워크 연결 상태 확인 함수: 포털 서버 접근 가능 여부를 확인합니다
local function checkNetworkConnection(callback)
    local host = portalHost
    log("네트워크 연결 상태 확인 중... (대상: " .. host .. ")")
    
    -- reachability 객체 생성: 네트워크 도달 가능성 테스트
    local reachability = hs.network.reachability.forAddress(host)
    
    -- 타임아웃 설정 (15초): 무한 대기 방지
    local connectionTimeout = hs.timer.doAfter(15, function()
        log("네트워크 연결 확인 타임아웃. 로그인 시도 종료.")
        callback(false)  -- 타임아웃이 발생해도 로그인은 시도하지 않음
    end)
    
    if reachability then
        -- 연결 변경을 감지하는 콜백 설정: 네트워크 상태 변경 시 이벤트 처리
        reachability:setCallback(function(self, flags)
            -- 타임아웃 취소
            connectionTimeout:stop()
            
            -- flags 상태 확인: 1(reachable), 2(cellular), 3(reachable,isLocal) 모두 연결 가능으로 처리
            if flags == 1 or flags == 2 or flags == 3 then
                log("네트워크가 도달 가능한 상태입니다. 상태 코드: " .. flags)
                callback(true)
                -- 일회성 확인 후 콜백 제거
                self:setCallback(nil)
            else
                log("아직 네트워크가 도달 가능한 상태가 아닙니다. 상태 코드: " .. flags)
            end
        end)
        
        -- 즉시 현재 상태 확인: 지연 없이 연결 가능한지 테스트
        local status = reachability:status()
        if status == 1 or status == 2 or status == 3 then
            -- 타임아웃 취소
            connectionTimeout:stop()
            
            log("네트워크 즉시 도달 가능: 상태 코드 " .. status)
            callback(true)
            reachability:setCallback(nil)
        else
            log("네트워크 도달 가능 상태 대기 중... 현재 상태 코드: " .. status)
            -- 모니터링 시작
            reachability:start()
        end
    else
        -- 타임아웃 취소
        connectionTimeout:stop()
        
        -- reachability 객체 생성 실패: 대체 방식으로 HTTP 요청 사용
        log("reachability 객체 생성 실패. HTTP 요청으로 대체합니다.")
        -- 백업 방법: HTTP 요청으로 확인
        hs.http.asyncGet("http://" .. host, nil, function(status, body, headers)
            if status ~= nil then
                log("HTTP를 통한 네트워크 연결 확인 성공: 상태 코드 " .. status)
                callback(true)
            else
                log("HTTP를 통한 네트워크 연결 확인 실패")
                callback(false)
            end
        end)
    end
end

-- WiFi 연결 변경 감지 및 처리 함수: SSID 변경 시 실행됩니다
local function wifiChangedCallback()
    local currentNetwork = hs.wifi.currentNetwork()
    
    if currentNetwork == ssidTarget then
        log("대상 네트워크 " .. ssidTarget .. "에 연결됨")
        
        -- 이미 로그인 작업이 진행 중인 경우 중복 실행 방지
        if isLoginInProgress then
            log("이미 로그인 작업이 진행 중입니다. 중복 실행 방지.")
            return
        end
        
        -- 로그인 작업 시작 설정
        isLoginInProgress = true
        
        -- 캡티브 포털이 준비될 때까지 잠시 대기: 네트워크 연결 안정화 시간
        hs.timer.doAfter(2, function()
            -- 네트워크 연결 상태 확인
            checkNetworkConnection(function(isReachable)
                if isReachable then
                    log("포털 서버에 도달할 수 있음. 로그인 진행...")
                    getLoginPageAndTokens()
                else
                    log("포털 서버에 도달할 수 없음. 네트워크 상태를 다시 확인해주세요.")
                    -- 로그인 작업 종료 설정 (실패한 경우)
                    isLoginInProgress = false
                end
            end)
        end)
    else
        if currentNetwork then
            log("다른 네트워크에 연결됨: " .. currentNetwork)
        else
            log("WiFi 연결이 끊어짐")
        end
    end
end

-- WiFi 연결 변경 이벤트 감지기 설정 및 시작
wifiWatcher = hs.wifi.watcher.new(wifiChangedCallback)
wifiWatcher:start()

-- 스크립트 시작 메시지
log("KBU_PUBLIC 자동 로그인 스크립트가 시작됨")

-- 스크립트 시작 시 현재 연결 상태 확인: 이미 대상 네트워크에 연결된 경우를 처리
wifiChangedCallback()

-- 반환값: 스크립트 종료 시 wifiWatcher 정리용
return wifiWatcher
