# prompt

Claude Code 커스텀 스킬 모음.

## 스킬 목록

| 스킬 | 설명 |
|---|---|
| [ogt-advisor](commands/ogt-advisor/) | Opus(설계/리뷰) + Codex(구현) 3-에이전트 자동 오케스트레이션 |

## 설치

```bash
git clone https://github.com/OhGyeongtaek/prompt.git
cd prompt
./scripts/install.sh
```

`~/.claude/commands/`에 심볼릭 링크가 생성되어 모든 프로젝트에서 사용 가능.

## 사용

```bash
# Claude Code에서
/ogt-advisor 백테스트 엔진 만들어줘
```

비용 절감을 위해 메인 세션을 Sonnet으로 전환 후 사용 권장:

```bash
/model sonnet
/ogt-advisor 작업 지시
```

## 구조

```
prompt/
├── README.md
├── commands/                ← 스킬 프롬프트
│   └── ogt-advisor/
│       ├── ogt-advisor.md   ← 스킬 정의
│       └── WORKFLOW.md      ← 워크플로우 문서
├── templates/               ← 공유 템플릿
│   └── codex-plan.md        ← 설계 파일 템플릿
└── scripts/
    └── install.sh           ← 심볼릭 링크 설치
```

## 사전 요구사항

- [Claude Code](https://claude.com/claude-code)
- [Codex CLI](https://github.com/openai/codex) (ogt-advisor용)
