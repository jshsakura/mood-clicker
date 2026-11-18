# tool/team

여러 에이전트 세션이 한 저장소에서 같이 일할 때 쓰는 도구입니다. tmux 가 필요합니다.

```bash
tool/team/start.sh claude ui api       # 팀장 팬 1개와 작업자 ui, api. 작업자는 ../<저장소>-<이름> worktree 에서 시작
tool/team/start.sh -n 3 codex          # 작업자 w1, w2, w3
tool/team/start.sh -s team -b main claude ui   # 세션 이름, 분기 기준 지정
tmux attach -t <세션>                  # 붙기. 다시 실행해도 있는 것은 만들지 않고 새 이름만 더합니다

tool/team/itl list                     # 팬과 이름
tool/team/itl whoami                   # 이 팬의 이름
tool/team/itl name <이름>               # 이 팬에 이름 붙이기
tool/team/itl send leader '끝났습니다'   # 팬에 글 보내기. 끝에 Enter 를 누릅니다(--no-enter 로 끔)
tool/team/itl read ui -n 60            # 팬 화면 마지막 줄들
tool/team/itl doctor                   # 점검
```

`itl` 은 표준 라이브러리만 쓰는 파일 하나입니다. 경로에 두고 `itl send ...` 로 부르려면 `tool/team` 을 `PATH` 에 넣습니다.
받는 쪽이 에이전트가 아니라 셸이면 보낸 글이 명령으로 실행되니 에이전트 팬에만 보냅니다.
