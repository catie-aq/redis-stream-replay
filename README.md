# Redis data player

This is a proof of concept of implementation of Redis data player. The data player replays data from Redis Stream in realtime. 

Every input that is read is `SET` and `PUBLISHED` on the corresponding key. 


## Running


### Frontend 
The codebase comes from Stimulus by Basecamp. 


```
$ yarn install
$ yarn build
```

### Backend 

The backend is a sinatra application, reading keys from Redis. 

```
$ cd server
$ ruby app.rb
```

### Connection 

Enter your Redis URL, port and password if any. 

You can list all keys, and read ones set with `SET` commands. 
You can "replay" data that was inserted with `XADD`. 

The inserted data will be replayed as `PUBLISH` events. It is 
replayed in realtime given a fixed error step. 