# 概要
この説明は、ハンズオン課題における`Sprint2：AWS基本サービス2`にて必要となる、APIサーバ（EC2インスタンス）からDBサーバ（RDS）に接続するための設定を説明しています。

# 前提
- APIサーバのEC2インスタンスにsshなどでログインしていること

# 手順

## 1. mysqlのインストール

パッケージマネージャー（yum）の更新を行います。
```shell
sudo yum update -y
```

MySQLの公式リポジトリをシステムに追加します。
```shell
sudo yum install https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
```

MySQLサーバのインストールを行います。
```shell
sudo yum install mysql-community-server -y
```

MySQLサービスの起動を行います。
```shell
sudo systemctl start mysqld
```

システム起動時にMySQLが自動起動するように設定します。
```shell
sudo systemctl enable mysqld
```

### 2. RDSに接続

以下のコマンドで、RDSのMySQLに接続
```
mysql -h 【エンドポイント】 -P 3306 -u 【ユーザ名】 -p
```

AWS RDSインスタンスのMySQLデータベースに接続します。以下のコマンドを実行前に、適切なエンドポイントとユーザ名に置き換えてください。また、パスワードの入力を求められるため、はRDSインスタンス作成時に指定したものを入力してください。


### 3. データベースとテーブルの作成

`reservation_db`データベースを作る
```sql
create database reservation_db;
```

`Reservations`テーブルを作成する
```sql
CREATE TABLE reservation_db.Reservations (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    reservation_date DATE NOT NULL,
    number_of_people INT NOT NULL
);
```

`Reservations`テーブルにサンプルデータを1件追加する
```sql
INSERT INTO reservation_db.Reservations (company_name, reservation_date, number_of_people)
VALUES ('株式会社テスト', '2024-04-21', 5);
```

テーブルにデータが登録されているかを確認
```sql
SELECT * FROM reservation_db.Reservations;
```

mysqlからログアウトする
```sql
exit
```

### 4. 設定ファイルの作成
GoのアプリケーションからRDSに接続するための設定ファイルを作成します。

`vi`コマンドで`.env`ファイルを作成する

```shell
vi cloudtech-reservation-api/.env
```

以下の内容を記載する
```
DB_USERNAME=admin
DB_PASSWORD=【RDSインスタンスのパスワード】
DB_SERVERNAME=【RDSインスタンスのエンドポイント】
DB_PORT=3306
DB_NAME=reservation_db
```

### 5. プロセスの再起動
`.env`ファイルの設定を反映させるため、プロセスの再起動を行う

8080ポートのPIDを取得する
```shell
sudo lsof -i :8080
```

表示される`PID`を終了する
```shell
sudo kill -9 【PID】
```

プロセスが終了すると、自動的に新しいGoアプリケーションのプロセスが立ち上がってくるので、`.env`ファイルの変更が反映される

### 6. 動作確認
以下のCURLコマンドでデータベース接続の確認を行う
```shell
curl http://localhost:8080/test
```







