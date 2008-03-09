#@since 1.9.0
= 多言語化

Ruby は複数の文字エンコーディングを扱うことができます。
文字列の内部表現のエンコーディングは固定されていません。
全ての文字列は自身のエンコーディング情報を保持します。

Ruby スクリプトにもマルチバイト文字列を使うことができます。
文字列リテラルや正規表現リテラルだけでなく変数名、メソッド名、クラス名などにも
マルチバイトの文字列を使うことができます。ただし文字列・正規表現リテラル以外でのマルチバイト文字列の使用は
推奨されません。

グローバル変数 [[m:$KCODE]] は廃止されました。

=== M17N プログラミングの基本

Ruby の文字列が生成される段階で自身の適切なエンコーディング情報を持つよう、
プログラマは常に意識してプログラミングしなければいけません。
文字列が生成されるのは主に「リテラルから」「IOから」 
「文字列操作から」の 3 通りです。このうち文字列操作に関しては Ruby インタプリタが適切に
処理しますから、プログラマは 「リテラルから生成」「IO から生成」 の二通りに関して注意する必要があります。
IO から生成される文字列のエンコーディングに関しては [[c:IO]] を参照してください。

=== Ruby がサポートするエンコーディング

Ruby のエンコーディングのサポートはその種類によって異なります。

: ASCII互換エンコーディング
  フルサポートです。UTF-8, EUC-JP, Shift_JIS などがこれにあたります。
: ASCII互換ではないエンコーディング
  スクリプトエンコーディングに使えません。またエンコーディングが固定されていない
  正規表現がマッチングを行うと例外が発生します。UTF-16LE, UTF-16BE などがこれにあたります。
: ダミーエンコーディング
  サポートしません。Ruby はエンコーディングの名前だけ知っている状態です。ISO-2022-JP, UTF-7 
  がこれにあたります。

サポートするエンコーディングのリストは [[m:Encoding.list]], [[m:Encoding.name_list]]
で取得することができます。
また拡張ライブラリを作成することによりサポートするエンコーディングを動的に増やすことができます。

それぞれの用語の定義は以下を参照してください。

==== ASCII互換エンコーディング

「ASCII互換エンコーディング」とは、ASCII 文字を表すバイト列が US-ASCII エンコーディングのバイト列
と同じエンコーディングを意味します。
コードポイントが同一という意味ではありません。従って UTF-16 はASCII互換ではありません。
また厳密性を追求せず、おおむね互換なら互換と呼びます。よって Shift_JIS は ASCII 互換です。

==== 7bit クリーンな文字列

ASCII 互換エンコーディングをもつ 7bit クリーンな文字列は
エンコーディングに関わらず ASCII として扱うことができます。
例えば [[m:String#==]] は両者の文字エンコーディングが異なっていても
true を返します。
ASCII 互換エンコーディングをもつ文字列にエンコーディングの変換なしで結合することができます。

例:

  s = "abc"
  a = s.encode("EUC-JP")
  b = s.encode("UTF-8")
  p a == b                           #=> true
  p a + b                            #=> "abcabc"

==== バイナリの取扱い

Ruby はバイナリをエンコーディングが ASCII-8BIT である文字列として扱います。

==== ダミーエンコーディング
#@todo

ダミーエンコーディングとは Ruby インタプリタが名前を知っているが対応していないエンコーディングのことです。
実際には ISO-2022-JP や UTF-7 などステートフルエンコーディングがダミーエンコーディングになります。
ダミーであるかどうかは [[m:Encoding#dummy?]] を使って識別できます。
ダミーエンコーディングを持つ文字列の扱いは以下のように制限されます。

 * 文字列のインスタンスメソッドは 1 文字ではなく 1 バイトを単位として動作します。
 * エンコーディングの異なる 7bit クリーンな文字列との結合ができません。例外が発生します。

またダミーエンコーディングはスクリプトエンコーディングとして使うことができません。

例:
  s = "漢字".encode("ISO-2022-JP")
  p s[0]   #=> "\e"  
  s + "b"  #=> ArgumentError: character encodings differ: ISO-2022-JP and US-ASCII

=== スクリプトエンコーディング

スクリプトエンコーディングとは Ruby スクリプトのエンコーディングです。
magic comment で指定します。
現在のスクリプトのエンコーディングは __ENCODING__ により取得することができます。

例: 
  # t.rb の内容
  # coding: euc-jp
  p __ENCODING__

  # 実行結果
  $ ruby t.rb
  #<Encoding:EUC-JP>

==== magic comment

magic comment とはスクリプトファイルの1行目に書かれた
 
  # coding: euc-jp

という形式のコメントのことです。1 行目が shebang である場合、magic comment は 2 行目に
書くことができます。上の形式以外にも

 # encoding: euc-jp
 # -*- coding: euc-jp -*-
 # vim:set fileencoding=euc-jp

などの形式を解釈します。

magic comment を使うことによりスクリプトファイル毎にスクリプトエンコーディングを
指定することができます。あるファイルにマルチバイト文字列を使う場合、magic comment を
必ず設定しなければいけません。設定されていなかった場合、エラーになります。

magic comment が指定されなかった場合、コマンド引数 -K, RUBYOPT およびファイルの shebang から
スクリプトエンコーディングは以下のように決定されます。左が優先です。

 magic comment(最優先) > -K > RUBYOPT > shebang 

上のどれもが指定されていない場合、通常のスクリプトなら US-ASCII、-e や stdin から実行されたものなら
locale がスクリプトエンコーディングになります。

==== 1.8 からのスクリプトエンコーディングに関する非互換性

 * スクリプトのリテラル中にマルチバイト文字列が含まれている場合、
   1.8 では -K オプションなしで正常に動作していたとしても、1.9 では必ずパース時に
   エラーになります。
   -K オプションがない場合、1.8 では 1.9 の ASCII-8BIT 相当の挙動でしたが、1.9
   では US-ASCII として扱われるためです。

 * magic comment があった場合、1.8 では無視されますが、1.9 ではそれ
   がスクリプトエンコーディングに反映されます。-K オプションよりも優先されます。

 * -K オプション・RUBYOPT・shebang の間の優先順位が 1.8 と 1.9 では違います。
   それぞれの優先順位は以下の通りです。左が優先です。
//emlist{
    Ruby 1.8 : shebang > RUBYOPT > -K
    Ruby 1.9 : -K      > RUBYOPT > shebang
//}

==== リテラルのエンコーディング

文字列リテラル、正規表現リテラルそしてシンボルリテラルから生成されるオブジェクトのエンコーディングは
スクリプトエンコーディングになります。
ただしそれらが 7bit クリーンである場合、エンコーディングは US-ASCII になります。

スクリプトエンコーディングが明示的に指定されていない場合、7bit クリーンではない
バックスラッシュ記法で表記されたリテラルのエンコーディングは ASCII-8BIT になります。

例: 
  # t.rb の内容
  p __ENCODING__
  p "abc".encoding
  p "\x80".encoding
 
  # 実行結果
  $ ruby t.rb
  #<Encoding:US-ASCII>
  #<Encoding:US-ASCII>
  #<Encoding:ASCII-8BIT>

  $ ruby -Ke t.rb
  #<Encoding:EUC-JP>
  #<Encoding:US-ASCII>
  #<Encoding:EUC-JP>

#@end
