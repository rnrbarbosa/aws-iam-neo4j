// #1 LOAD POLICIES
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.Policies[*]') YIELD value as row
MERGE(p:IAM_Policy {id:row.PolicyId, name:row.PolicyName, arn:row.Arn})

// #2 LOAD GROUPS
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.GroupDetailList[*]') YIELD value as row
MERGE(p:IAM_Group {id:row.GroupId, name:row.GroupName, arn:row.Arn})

// #3 Load User and relationship to Groups,Policies
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.UserDetailList[*]') YIELD value as row
UNWIND row.AttachedManagedPolicies as policy
UNWIND row.GroupList as group
CREATE (u:IAM_User {id:row.UserId,name:row.UserName})
WITH u,policy, group
MATCH (p:IAM_Policy {name:policy.PolicyName})
CREATE (u)-[:HAS_POLICY]->(p)
WITH u,p, group
MATCH (g:IAM_Group {name:group})
CREATE (u)-[:MEMBER_OF]->(g)


// #4 Create relationship btw Groups and Policies
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.GroupDetailList[*]') YIELD value as row
UNWIND row.AttachedManagedPolicies as policy
MATCH (g:IAM_Group {name:row.GroupName})
MATCH (p:IAM_Policy {name:policy.PolicyName})
CREATE (g)-[:HAS_POLICY]->(p)

// #5  Create Policy Actions and relate it to the Policy
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json") YIELD value as row
UNWIND row.Policies as p
UNWIND p.PolicyVersionList as a
UNWIND a.Document as d
UNWIND d.Statement as s
UNWIND s.Action as act
WITH p.PolicyName as pol, act as action
MATCH (p1:IAM_Policy {name:pol})
MERGE(a1:IAM_Policy_Action {action:action})
CREATE(p1)-[:has_action]->(a1)

// #6  Create Policy Resources and relate it to the Policy
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json") YIELD value as row
UNWIND row.Policies as p
UNWIND p.PolicyVersionList as a
UNWIND a.Document as d
UNWIND d.Statement as s
UNWIND s.Resource as res
WITH p.PolicyName as pol, res as resource
MATCH (p1:IAM_Policy {name:pol})
MERGE(r1:IAM_Policy_Resource {name:resource})
CREATE(p1)-[:has_resource]->(r1)