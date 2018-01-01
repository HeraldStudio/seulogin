axios   = require 'axios'
read    = require 'readline-sync'
program = require 'commander'

program
  .version  '1.0.0'
  .option   '-u, --username [username]', '设置用户名'
  .option   '-p, --password [password]', '设置密码'
  .option   '-d, --daemon [seconds]', '每隔数秒轮询网络状态，一旦退出自动重新登录', '0'
  .parse    process.argv

process.on 'unhandledRejection', (e) -> throw e
process.on 'uncaughtException', (e) -> console.error e.message

seu = axios.create
  baseURL: 'http://w.seu.edu.cn/index.php/index/'
  timeout: 3000
  validateStatus: -> true
  headers:
    'Content-Type': 'application/x-www-form-urlencoded'

daemonInterval = parseInt program.daemon

main = ->
  if daemonInterval
    username = program.username or read.question '用户名：'
    password = program.password or read.question '密码：'
    password = (new Buffer password).toString 'base64'

    loop
      try
        status = await seu.get 'init'
        console.log new Date(), status.data.info

        unless status.data.status
          status = await seu.post 'login', 'username=' + username + '&password=' + password + '&enablemacauth=1'
          console.log new Date(), status.data.info
      catch e
        console.error e.message
      finally
        await new Promise (r) -> setTimeout r, daemonInterval * 1000

  else
    status = await seu.get 'init'
    console.log status.data.info

    if status.data.status
      if (read.question '是否退出？y/N：').toLowerCase() is 'y'
        status = await seu.get 'logout'
        console.log status.data.info

    else
      username = program.username or read.question '用户名：'
      password = program.password or read.question '密码：'
      password = (new Buffer password).toString 'base64'
      status = await seu.post 'login', 'username=' + username + '&password=' + password + '&enablemacauth=1'
      console.log status.data.info

  return

main()
