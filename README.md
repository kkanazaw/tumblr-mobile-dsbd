# tumblr-mobile-dsbd
==================

スマートフォンからタップでreblogするためのツールです。
個人的にherokuに設置して使っています。

## 設置方法

tumblrのサイトでAPIKeyを取得
herokuにアプリをデプロイします。
アプリケーションの登録を行い、Consumer KeyとConsumer Secretを取得します。
アプリの認証を行って、AccessTokenとAccessTokenSecretを取得します。
取得したtokenをheroku環境変数に設定します。


      ACCESS_SECRET=
      ACCESS_TOKEN=
      CONSUMER_KEY=
      CONSUMER_SECRET=
      BASIC_AUTH_USERNAME={任意のユーザー名}
      BASIC_AUTH_PASSWORD={任意のパスワード}
