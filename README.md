
# 🔐 KBU_PUBLIC 자동 로그인 스크립트

교내 와이파이를 이용하며, 캡티브 포탈이 주기적으로 열려 로그인해야하는 번거로움이 있어 제작했습니다.
이 Lua 스크립트는 **macOS의 Hammerspoon** 환경에서 실행되며, 학교 WiFi인 `KBU_PUBLIC`에 연결될 때 자동으로 로그인합니다.
---

## 🛠 주요 기능

- SSID `KBU_PUBLIC` 연결 시 자동 로그인
- 로그인 페이지로부터 동적 토큰 추출 및 쿠키 처리
- 로그인 성공 여부 판별 및 인터넷 연결 확인
- WiFi 상태 변화 감지 및 자동 재시도
- 메뉴바에 알림 표시 (`hs.alert` 사용)

---
## Diagram
``` mermaid
%%{init: {'themeVariables': {fontSize: '10px'}, 'flowchart': {'nodeSpacing': 10, 'rankSpacing': 10}}}%%
flowchart TD
    HS["Hammerspoon Host (macOS Runtime)"]:::host
    README["README.md"]:::doc

    subgraph "Automation Script (init.lua)"
        WF["Wi-Fi Watcher"]:::internal
        HC["HTTP Client"]:::internal
        TE["Token Extractor"]:::internal
        LM["Login Manager"]:::internal
        CC["Connectivity Checker"]:::internal
        NT["Notifier"]:::internal
    end

    Web["Captive Portal Web Server"]:::external
    Int["Internet (Connectivity Test)"]:::external

    HS -->|"Network Change (SSID KBU_PUBLIC)"| WF
    WF -->|"Detect captive portal / HTTP GET"| HC
    HC -->|"HTML Response"| TE
    TE -->|"Parsed Token"| LM
    LM -->|"POST credentials+token"| Web
    Web -->|"200 OK + cookies"| LM
    LM -->|"Verify Internet"| CC
    CC -->|"GET known site"| Int
    CC -->|"Success/Failure"| NT

    click README "https://github.com/cherryshine/project-wifi-autologin/blob/main/README.md"
    click WF "https://github.com/cherryshine/project-wifi-autologin/blob/main/init.lua"
    click HC "https://github.com/cherryshine/project-wifi-autologin/blob/main/init.lua"
    click TE "https://github.com/cherryshine/project-wifi-autologin/blob/main/init.lua"
    click LM "https://github.com/cherryshine/project-wifi-autologin/blob/main/init.lua"
    click CC "https://github.com/cherryshine/project-wifi-autologin/blob/main/init.lua"
    click NT "https://github.com/cherryshine/project-wifi-autologin/blob/main/init.lua"

    classDef host fill:#f9f,stroke:#333,stroke-width:1px
    classDef internal fill:#bbf,stroke:#333,stroke-width:1px
    classDef external fill:#ccc,stroke:#333,stroke-width:1px
    classDef doc fill:#afa,stroke:#333,stroke-width:1px

    linkStyle 8 stroke:#0a0,stroke-width:2px



```
---

## 📦 사용 환경

- **운영체제:** macOS
- **필수 도구:** [Hammerspoon](http://www.hammerspoon.org/)

---

## 🔧 설치 및 설정 방법

### 1. Hammerspoon 설치
[공식 홈페이지](http://www.hammerspoon.org/)에서 설치 후 실행

### 2. 스크립트 파일 설정
- Hammerspoon 설정 디렉토리(`~/.hammerspoon/`)에 `init.lua` 파일을 생성
- 또는 `init.lua`에 본 스크립트를 복사

### 3. 사용자 계정 정보 입력
`init.lua`에서 다음 항목을 본인의 계정으로 수정하세요:

```lua
local username = "your_username"
local password = "your_password"
```

> 학교 인트라넷 로그인 계정 정보를 사용합니다.

### 4. Hammerspoon Reload
- 메뉴바의 Hammerspoon 아이콘 클릭
- `Reload Config` 선택 또는 콘솔에서 `:reload()`

---

## ▶️ 사용 방법

1. Wi-Fi를 `KBU_PUBLIC`에 연결합니다.
2. Hammerspoon이 자동으로 로그인 시도를 감지하고 수행합니다.
3. 성공 시 알림이 표시되고 인터넷 사용이 가능해집니다.

---

## 🧪 예시 동작 로그

```
2025-04-08 10:15:20 [KBU_AUTO] 대상 네트워크 KBU_PUBLIC에 연결됨
2025-04-08 10:15:23 [KBU_AUTO] 포털 서버에 도달할 수 있음. 로그인 진행...
2025-04-08 10:15:25 [KBU_AUTO] 로그인 페이지 로드 성공
2025-04-08 10:15:25 [KBU_AUTO] 토큰 추출 성공: uip=..., LoginFromForm=...
2025-04-08 10:15:27 [KBU_AUTO] 로그인 성공 확인됨!
```

---

## ⚠️ 주의사항

- **비밀번호는 스크립트에 평문으로 저장**되므로, GitHub 등 **공개 저장소에 업로드하지 마세요.**
- 포털 페이지 구조가 변경될 경우 스크립트가 작동하지 않을 수 있습니다.
- macOS 전용이며, Windows에서는 작동하지 않습니다.

---


## 📄 라이선스

MIT License. 자유롭게 수정 및 활용 가능합니다.
