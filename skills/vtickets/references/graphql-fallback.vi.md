# Fallback GraphQL để link sub-issue

Chỉ dùng khi lệnh REST `POST .../sub_issues` fail với lỗi khác 401/403 (404, 410, 422, lỗi mạng). 401/403 nghĩa là token thiếu quyền và GraphQL cũng sẽ fail y hệt, nên hãy báo lỗi thay vì fallback.

1. Lấy node ID của epic và của sub-issue (chạy một lần cho mỗi issue, `<number>` là số của issue đó):

```bash
gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<number>
```

2. Link chúng. `replaceParent: true` chuyển sub-issue đang thuộc parent khác sang epic này, giống `replace_parent` của REST:

```bash
gh api graphql -f query='mutation($issueId:ID!,$subIssueId:ID!,$replaceParent:Boolean){addSubIssue(input:{issueId:$issueId,subIssueId:$subIssueId,replaceParent:$replaceParent}){issue{title}subIssue{title}}}' -f issueId=<epic_node_id> -f subIssueId=<sub_issue_node_id> -F replaceParent=true
```
