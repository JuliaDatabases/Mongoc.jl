
# Authentication

Refer to the [Security section of the MongoDB Manual](https://docs.mongodb.com/manual/security/)
for an overview on how authentication works in MongoDB.

## Basic Authentication (SCRAM)

In this authentication mechanism, user and passwords are passed in the URI string for the `Mongoc.Client`.

### Enable Auth

To use basic authentication mechanism, first enable authentication in the database,
as described in the [MongoDB manual](https://mongoc.org/libmongoc/current/authentication.html).

#### 1. Start MongoDB without access control

```shell
$ mongod --dbpath ./db
```

#### 2. Connect to the database and create an admin user.

From a Julia session, you can use `Mongoc.add_user` to add users to a MongoDB database.

```julia
import Mongoc
roles = Mongoc.BSON("""[ { "role" : "userAdminAnyDatabase", "db" : "admin" }, "readWriteAnyDatabase" ]""")
client = Mongoc.Client()
Mongoc.add_user(client["admin"], "myUserAdmin", "abc123", roles)
Mongoc.destroy!(client) # or exit julia session
```

#### 3. Re-start the MongoDB instance with access control

Kill the previous process running `mongod` and then start server with auth option.

```shell
$ mongod --auth --dbpath ./db
```

### Connect and authenticate

Pass the user and password in the URI, as described in [https://mongoc.org/libmongoc/current/authentication.html](https://mongoc.org/libmongoc/current/authentication.html).

```julia
client = Mongoc.Client("mongodb://myUserAdmin:abc123@localhost/?authSource=admin")
```

From MongoDB 4.0, there's a new authentication mechanism SCRAM-SHA-256, which replaces the previous SCRAM-SHA-1 mechanism.
The correct authentication mechanism is negotiated between the driver and the server.

Alternatively, SCRAM-SHA-256 can be explicitly specified:

```julia
client = Mongoc.Client("mongodb://myUserAdmin:abc123@localhost/?authMechanism=SCRAM-SHA-256&authSource=admin")
```

Refer to the [MongoDB manual](https://docs.mongodb.com/manual/security/) for adding new users and roles per database.
