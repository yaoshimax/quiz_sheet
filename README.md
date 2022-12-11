# quiz_sheet

flutter で作ったスプレッドシートの表を単語帳みたく出力してくれるアプリ

## こんなことができる

![demo](https://user-images.githubusercontent.com/2102714/206882531-fbab691d-0512-48e5-a697-34346168c34f.gif)

## おことわり

このコードは github にこそ公開していますが、apk ファイルをインストールして個人的に利用するために開発しています。  
特に、スプレッドシートにアクセスをするための実装は意図的に削除されていますので、このコードを clone して即座に動くものができるわけではありません。

実際にこのコードを動かすためには、  
main.dart の上部にある `_credentiails`, `_spreadsheetId` を編集し、
スプレッドシート にアクセスができるようにする必要があります。

記載する内容については、
https://medium.com/@a.marenkov/how-to-get-credentials-for-google-sheets-456b7e88c430 を参照してください。


また、スプレッドシートのフォーマットについては、  
https://docs.google.com/spreadsheets/d/1hkuHXmnUqacat5HEolzWSL6dmINg5swZPH4azAz2lgA/edit?usp=sharing の通りです。