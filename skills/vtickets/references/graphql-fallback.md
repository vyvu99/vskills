# GraphQL fallback for linking sub-issues

Use only when the REST `POST .../sub_issues` call fails with something other than 401/403 (404, 410, 422, network). A 401/403 means the token lacks permission and GraphQL would fail the same way, so report it instead.

1. Look up the node ID of the epic and of the sub-issue (run once for each, with `<number>` set to that issue's number):

```bash
gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<number>
```

2. Link them. `replaceParent: true` moves a sub-issue that belongs to another parent, matching the REST `replace_parent` behaviour:

```bash
gh api graphql -f query='mutation($issueId:ID!,$subIssueId:ID!,$replaceParent:Boolean){addSubIssue(input:{issueId:$issueId,subIssueId:$subIssueId,replaceParent:$replaceParent}){issue{title}subIssue{title}}}' -f issueId=<epic_node_id> -f subIssueId=<sub_issue_node_id> -F replaceParent=true
```
