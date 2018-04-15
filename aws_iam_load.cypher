// LOAD POLICIES
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.Policies[*]') YIELD value as row
MERGE(p:IAM_Policy {id:row.PolicyId, name:row.PolicyName, arn:row.Arn})

// LOAD GROUPS
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.GroupDetailList[*]') YIELD value as row
MERGE(p:IAM_Group {id:row.GroupId, name:row.GroupName, arn:row.Arn})

// Load User and relationship to Groups,Policies
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.UserDetailList[*]') YIELD value as row
UNWIND row.AttachedManagedPolicies as policy
UNWIND row.GroupList as group
CREATE (u:IAM_User {id:row.UserId,name:row.UserName,arn:row.Arn})
WITH u,policy, group
MATCH (p:IAM_Policy {name:policy.PolicyName})
CREATE (u)-[:HAS_POLICY]->(p)
WITH u,p, group
MATCH (g:IAM_Group {name:group})
CREATE (u)-[:MEMBER_OF]->(g)

// Load Roles and attached Policies to the Roles
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.RoleDetailList[*]') YIELD value as row
UNWIND row.AttachedManagedPolicies as policy
UNWIND policy as pol
WITH row.RoleName as role, row.Path as path, row.Arn as arn, pol.PolicyName as pol
MERGE(r:IAM_Role {name:role, path:path, arn:arn})
MERGE(r)-[:HAS_POLICY]->(p)

// Create relationship btw Groups and Policies
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.GroupDetailList[*]') YIELD value as row
UNWIND row.AttachedManagedPolicies as policy
MATCH (g:IAM_Group {name:row.GroupName})
MATCH (p:IAM_Policy {name:policy.PolicyName})
CREATE (g)-[:HAS_POLICY]->(p)

// Create Policy Actions and relate it to the Policy
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json") YIELD value as row
UNWIND row.Policies as p
UNWIND p.PolicyVersionList as a
UNWIND a.Document as d
UNWIND d.Statement as s
UNWIND s.Action as act
WITH p.PolicyName as pol, act as action
MATCH (p1:IAM_Policy {name:pol})
MERGE(a1:IAM_Policy_Action {action:action})
CREATE(p1)-[:HAS_ACTION]->(a1)

// Create Policy Resources and relate it to the Policy
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json") YIELD value as row
UNWIND row.Policies as p
UNWIND p.PolicyVersionList as a
UNWIND a.Document as d
UNWIND d.Statement as s
UNWIND s.Resource as res
WITH p.PolicyName as pol, res as resource
MATCH (p1:IAM_Policy {name:pol})
MERGE(r1:IAM_Policy_Resource {name:resource})
CREATE(p1)-[:HAS_RESOURCE]->(r1)


// Load Services 
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.RoleDetailList[*]') YIELD value as row
UNWIND row.AssumeRolePolicyDocument as arpd
UNWIND arpd.Statement as stmt
WITH stmt,row.RoleName as role
WHERE stmt.Effect = 'Allow' 
UNWIND keys(stmt.Principal) AS key
WITH role,key, stmt.Principal as princ
WHERE key = 'Service'
MATCH(r:IAM_Role {name:role})
CREATE(s:AWS_Service {name: princ[key] })
CREATE (s)-[:CAN_ASSUME_ROLE]->(r)

// Load Principal and Roles that can Assume
CALL apoc.load.json("file:/Users/rnrbarbosa/Downloads/account_auth.json",
'.RoleDetailList[*]') YIELD value as row
UNWIND row.AssumeRolePolicyDocument as arpd
UNWIND arpd.Statement as stmt
WITH stmt,row.RoleName as role
WHERE stmt.Effect = 'Allow' 
UNWIND keys(stmt.Principal) AS key
WITH role,key, stmt.Principal as princ
WHERE key = 'AWS'
MERGE(u:IAM_User {arn:princ[key]})
MERGE(r:IAM_Role {name:role})
CREATE (u)-[:CAN_ASSUME_ROLE]->(r)
RETURN u,r