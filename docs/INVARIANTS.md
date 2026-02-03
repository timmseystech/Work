# Invariants (Strict)

1) logs/state_index.json MUST be a JSON array.
2) Save-state tags MUST be annotated and named ai-state/<slug>.
3) Restore MUST refuse dirty working trees.
4) Work identity MUST apply under C:\Users\TimmseysTech\src\work\ via includeIf.
5) AI logs MUST be GitHub-synced (force-add allowed for logs/AI_*.log and logs/AI_STATE_*.log).
6) No GUI automation, no background agents unless explicitly requested.
