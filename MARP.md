---
marp: true
paginate: true
class: lead

# VSCode の Marp 拡張はまだカスタム CSS をサポートしていない。ので、一時的に gaia テーマをあてる用にコメントを入れておく。
# See: https://github.com/marp-team/marp-vscode/issues/39
theme: gaia
---
# Flutter/Dart における FFI
<!-- _footer: Flutter Meetup Tokyo #10 -->

---
## 今日話すこと
# dart:ffi の実装が始まった背景と課題
---
# FFI ？
---
<h1>
  <span style="color:red;">F</span>oreign <span style="color:red">f</span>unction <span style="color:red">i</span>nterface</span>
</h1>
<br>

#####  今回は C 呼び出しの話
###### (C -> Dart の話は省きます)
---
# 自己紹介
---
<!-- _header: 自己紹介 -->
![bg right w:300](./assets/icon.jpg)
## しみず なおき

<br>

<a href="https://github.com/sensuikan1973" target="_blank"><img src="assets/GitHub-icon.png" style="border:none;" alt="sensuikan1973 Github"></i></a>

---
<!-- _header: 自己紹介 -->
![w:800](./assets/othello.jpg)

---
<!-- _header: 自己紹介 -->
# お家で作ってるモノ
---
![center w:800](./assets/architecture.png)

---
<!-- _header: 自己紹介 -->
# オセロには常に C が必要
---
<!-- _header: 自己紹介 -->
![center w:800](./assets/architecture_marked.png)

---
<!-- _header: 前置き -->
# 各言語の C 呼び出し
---
<!-- _header: 前置き -->
### 代表的なもの
| 言語 | 実装方法 |
| :-----: | :-----: |
| Java | <div style="text-align:left">[JNI](https://docs.oracle.com/javase/jp/8/docs/technotes/guides/jni/spec/jniTOC.html) や [JNA](https://github.com/java-native-access/jna), [SWIG](http://www.swig.org/) を使う</div> |
| Go | <div style="text-align:left">[cgo](https://golang.org/cmd/cgo/) を使う</div> |
| Python | <div style="text-align:left">[ctypes](https://docs.python.org/3/library/ctypes.html) や [cffi](https://cffi.readthedocs.io/en/latest/) を使う</div> |
| Rust | <div style="text-align:left">[extern キーワード](https://doc.rust-lang.org/book/ch19-01-unsafe-rust.html#using-extern-functions-to-call-external-code)で容易に呼べる</div>|
| Ruby | <div style="text-align:left">[Ruby-FFI](https://github.com/ffi/ffi) を使う</div> |
| Javascript | <div style="text-align:left">[WebAssembly](https://developer.mozilla.org/ja/docs/WebAssembly/C_to_wasm) を使う</div> |
| Swift | <div style="text-align:left">[そのままいける](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/using_imported_c_functions_in_swift)し、[カスタム](https://developer.apple.com/documentation/swift/objective-c_and_c_code_customization/customizing_your_c_code_for_swift)も可能 </div> |

---
# Dart は？
---
# Dart から C を呼ぶ方法 <br> (これまで)
---
<!-- _header: Dart から C を呼ぶ方法 (これまで) -->
# Native Extension
---
<!-- _header: Dart から C を呼ぶ方法 (これまで) -->
<!-- _class: default -->
#### Dart 側
<br>

<div style="font-size:35px;">

```dart
library sample_hello;
import 'dart-ext:sample_hello';
void hello() native "Hello";
```
</div>
<br>

<span style="font-size:30px;">参考: [dart-lang sample_extension](https://github.com/dart-lang/sdk/tree/master/samples/sample_extension)</span>

---
<!-- _header: Dart から C を呼ぶ方法 (これまで) -->
<!-- _class: default -->
#### C++ 側 <span style="font-size:24px;">(一部省略)</span>
<!--
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "include/dart_api.h"
#include "include/dart_native_api.h"
-->

<div style="font-size:20px;">

```cpp
DART_EXPORT Dart_Handle sample_hello_Init(Dart_Handle parent_library) {
  if (Dart_IsError(parent_library)) return parent_library;
  Dart_Handle result_code = Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if (Dart_IsError(result_code)) return result_code;
  return Dart_Null();
}

void hello(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  printf("Hello\n");
  Dart_ExitScope();
}

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope) {
  if (!Dart_IsString(name) || auto_setup_scope == NULL) return NULL;
  Dart_EnterScope();
  const char *cname;
  Dart_StringToCString(name, &cname);
  Dart_NativeFunction result = NULL;
  if (strcmp(cname, "hello") == 0) result = hello;
  Dart_ExitScope();
  return result;
}
```
</div>

👉 深いレベルで拡張可能
👉 都度 `ResolveName` する

---
<!-- _header: Dart から C を呼ぶ方法 (これまで) -->
<!-- _class: default -->
#### わかりやすく例をもう一個
```cpp
void isEven(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle arg1 = Dart_GetNativeArgument(arguments, 0);
  int64_t input;
  if (Dart_IsError(Dart_IntegerToInt64(arg1, &input)))
  {
    Dart_ThrowException(Dart_NewStringFromCString("Error だよ"));
  }
  Dart_SetReturnValue(arguments, Dart_NewBoolean(input % 2 == 0));
  Dart_ExitScope();
}
```
👉 引数と返り値の型情報が静的に定義されていない

---
# さて、Flutter では？
---
<!-- _header: Flutter から C を呼ぶ方法 -->
# 現状、Swift/Objective-C, Kotlin/Java を経由する必要がある
---
<!-- _header: Flutter から C を呼ぶ方法 -->
![center](./assets/flutter_support_c_cpp.png)

---
<!-- _header: Flutter から C を呼ぶ方法 -->
# たくさんの 👍 の思いは？
---
<!-- _header: Flutter から C を呼ぶ方法 -->
# ① 既存ソフトをより統合しやすくしてほしい
---
<!-- _header: Flutter から C を呼ぶ方法 -->
<!-- _class: default -->
<br>
<br>

# ◯ 大量のグルーコードがつらい

<br>
<br>

# ◯ 低オーバーヘッドがいい
---
<!-- _header: Flutter から C を呼ぶ方法 -->
## SQLite

## Realm

## OpenCV

## crypto, ssh ... libraries

などが具体例として挙げられている

---
<!-- _header: Flutter から C を呼ぶ方法 -->
# ② 大量のデータを効率よく出し入れしたい

<br>
<br>

##### なお、Dart 2.4 から [TransferableTypedData](https://api.dartlang.org/stable/2.4.0/dart-isolate/TransferableTypedData-class.html)  が使用できるようになったので、ある程度はそれで間に合いそう

---
# こういう要望にどう応えるか？
---
<!-- _header: Flutter/Dart における Dart->C をどう実現するか？ -->
## 「Native Exstention でいいんじゃないの...?」
---
![w:1000](./assets/support_native_extensions_issue.png)

---
<!-- _header: Flutter/Dart における Dart->C をどう実現するか？ -->
# 😣

<br>

###### ⇒ [Dart VM FFI Vision](https://gist.github.com/mraleph/2582b57737711da40262fad71215d62e) に理由が述べられていた
---
<!-- _header: Flutter/Dart における Dart->C をどう実現するか？ -->
<!-- _class: default -->
### 【 理由 1 】
## 名前ベースの API

```
// dart-lang/sdk/runtime/include/dart_api.h より引用
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_SetField(Dart_Handle container, Dart_Handle name, Dart_Handle value);
```

#### 👉 名前解決がキャッシュされない
#### 👉 AOT コンパイラに厳しい <br> <span style="font-size:27px;">(最悪の場合を想定したり、手動でアノテーションを付けてまわったりしないといけない) </span>

---
<!-- _header: Flutter における Dart->C をどう実現するか？ -->
<!-- _class: default -->
### 【 理由 2 】
## Reflective Marshaling は効率良くない

```cpp
void isEmailAddress(Dart_NativeArguments arguments)
```

`void` `arguments` 👀

#### ⇒ 引数/返り値が静的に型付けされた上での Marshaling の方が効率良い
#### ⇒ その点は FFI が優れている

---
# そこで、dart : ffi 👍

<br>
<br>

###### https://github.com/dart-lang/sdk/tree/master/sdk/lib/ffi

---
<!-- _header: dart:ffi -->
## [Google I/O'19](https://www.youtube.com/watch?v=J5DQRPRBiFI) でも言及あり
![center](./assets/dart_session_io19.png)
<b style="text-align:center">

> We are working on a new foreign function interface.
> This should help you reuse existing C and C++ code,
> which is important for some critical stuff
</b>

---
<!-- _header: dart:ffi -->
#### ちなみに
> we expect that moving Flutter Engine from C API to FFI should significantly reduce overheads associated with crossing the boundary between Dart and native code
---
<!-- _header: dart:ffi -->
# どう使えるのか？
---
<!-- _header: dart:ffi -->
<div style="font-size:35px;">

👍

```dart
import "dart:ffi" as ffi;
import 'dart:io' show Platform;

void main() {
  final libHelloWorld = ffi.DynamicLibrary.open("./libHelloWorld.dylib");
  final helloWorld = libHelloWorld.lookupFunction
  	<ffi.Void Function(), void Function()>("helloWorld");

  helloWorld();
}
```
</div>
<div style="font-size:30px;">

[https://github.com/sensuikan1973/Dart_FFI_Hello_World](https://github.com/sensuikan1973/Dart_FFI_Hello_World)
</div>

---
<!-- _header: dart:ffi -->
# ちなみに、先週、
# Flutter stable 版に入った

<br>

#### (Android のみで試験的に触れる)
---
<!-- _header: dart:ffi -->
# どういう構成になるのか
<!-- _footer: 参考: [dart-lang/sdk/samples/ffi/sqlite/docs/sqlite-tutorial.md](https://github.com/dart-lang/sdk/blob/master/samples/ffi/sqlite/docs/sqlite-tutorial.md) -->

---
<!-- _header: dart:ffi -->
![w:850](./assets/dart_ffi_architecture_without_c_glue_code.svg)

<div style="font-size: 25px;">

👉 Bindings: `final helloWorld = libHelloWorld.lookupFunction<ffi.Void Function(), void Function()>("helloWorld");` みたいなのを定義するレイヤーのこと
</div>

---
## 課題をいくつか紹介

<!-- _footer: 参考: [Dart VM FFI projects](https://github.com/dart-lang/sdk/projects/13), [design-scketch](https://gist.github.com/mraleph/2582b57737711da40262fad71215d62e#design-sketch), [sqlite sample](https://github.com/dart-lang/sdk/blob/master/samples/ffi/sqlite/docs/sqlite-tutorial.md#current-dartffi-development-status) -->

---
<!-- _header: dart:ffi -->
### 1: 例外を拾えない
### ⇒ C レイヤーを追加実装する

![w:850](./assets/dart_ffi_architecture.svg)

---
<!-- _header: dart:ffi -->
### 2: CFE への追加実装

![w:850](./assets/dart-to-kernel.png)

#### 補完や静的解析を行うために、<br>[CFE (Common Front-End)](https://github.com/dart-lang/sdk/tree/master/pkg/front_end) への追加実装が必要。

<span style="font-size:20px;">

*Dart2 VM からは、生のソースから Dart を直接実行できず、CFE によって生成された [Kernel Binary(dill)](https://github.com/dart-lang/sdk/blob/master/pkg/kernel/binary.md) を与える必要がある
</span>

---
<!-- _header: dart:ffi -->
### 3: サポート対象のプラットフォーム

待ちきれない人がスケジュールを聞く
⇒ 具体的なスケジュールは示さないけど、近い将来その状態になるから待っていよう
![w:850](./assets/support_ios.png)

---
<!-- _header: dart:ffi -->
### 4: 変更/削除時の HotReload 下での挙動は..?
![w:600](./assets/callbacks_hot_reload.png)
![w:650](./assets/flutter-cfe.png)

---
<!-- _header: dart:ffi -->
### その他タスクの詳細は <br>[Dart VM FFI projects](https://github.com/dart-lang/sdk/projects/13) を参照
<br>

##### 正直に言いますと、低レイヤの勉強不足で、<br>あまり理解できてないものが多い...

---
# 詳しい方は是非 [dart:ffi に FB](https://groups.google.com/forum/#!forum/dart-ffi) を送りましょう 👍
---
# ありがとうございました
---
<!-- _class: default -->
###### リンク一覧

<div style="font-size: 20px;">

- **[Dart VM FFI Vision](https://gist.github.com/mraleph/2582b57737711da40262fad71215d62e)**
  - **[Introduction to Dart VM](https://mrale.ph/dartvm/)**
  - [Design and implement Dart VM FFI](https://github.com/dart-lang/sdk/issues/34452)
  - [Flutter Support integrating with C/C++ in plugin framework](https://github.com/flutter/flutter/issues/7053)
  - [Native extensions for the standalone Dart VM](https://dart.dev/server/c-interop-native-extensions)
  - [Support for Dart Extensions](https://github.com/flutter/flutter/issues/2396)
  - [dart:ffi resolve outstanding design decisions](https://github.com/dart-lang/sdk/issues/35764)
- [C & C++ interop using FFI](https://dart.dev/server/c-interop)
  - **[sdk/lib/ffi/](https://github.com/dart-lang/sdk/tree/master/sdk/lib/ffi)**
  - [Dart Native platform ](https://dart.dev/platforms)
  - [dart:ffi sqllite sample](https://github.com/dart-lang/sdk/blob/master/samples/ffi/sqlite/README.md)
- [The Engine architecture](https://github.com/flutter/flutter/wiki/The-Engine-architecture)
  - [Writing custom platform-specific code](https://flutter.io/platform-channels/)
  - [Custom Flutter Engine Embedders](https://github.com/flutter/flutter/wiki/Custom-Flutter-Engine-Embedders)
- [Language features for FFI](https://github.com/dart-lang/language/issues/411)
- [sensuikan1973/flutter-ffi-slide](https://github.com/sensuikan1973/flutter-ffi-slide)
- [sensuikan1973/Dart_FFI_Hello_World](https://github.com/sensuikan1973/Dart_FFI_Hello_World)
</div>
