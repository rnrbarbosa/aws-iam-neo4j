# aws-iam-neo4j

## Export IAM Settings of you accout

Run the following command to extract all your AWS IAM settings:

```
aws iam get-account-authorization-details > account_auth.json
```

## Graph Schema

![AWS IAM Schema](./db_schema.png)


## Relevant Cypher Queries

### Show me a specific Policy and all related Relationships 
```
MATCH (p:IAM_Policy)-[]->(n)
WHERE p.name = '<PolicyName>'
RETURN n,p 
```

### Show me all Users
```
MATCH (u:IAM_User) RETURN u
```

### Show me all Users and their Groups
```
MATCH (u:IAM_User)-[]->(g:IAM_Group) RETURN u,g
```

### Show me all Groups with at least one User
```
MATCH (u:IAM_User)-[:MEMBER_OF]->(g:IAM_Group) 
WITH count(u) as n,u,g
WHERE n > 0
RETURN u,g
```

### Show me all Roles
```
MATCH (r:IAM_Role) RETURN r
```

### Show me all Roles with at least one Policy attached
```
MATCH (r:IAM_Role)-[]->(p:IAM_Policy) 
WITH count(p) as n, r, p
WHERE n > 0 
RETURN r,p
```
