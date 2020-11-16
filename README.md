# Redis data player

This is a proof of concept of implementation of Redis data player. The data player replays data from Redis Stream in realtime. 

Every input that is read is `SET` and `PUBLISHED` on the corresponding key. 


## Running


### Frontend 
The codebase comes from Stimulus by Basecamp. 


```
$ yarn install
$ yarn start
```


### Backend 

The backend is a sinatra application, reading keys from Redis. 

```
$ cd server
$ ruby app.rb
```
