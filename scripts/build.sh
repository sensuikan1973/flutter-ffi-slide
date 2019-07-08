THEME='themes/sensuikan1973_theme.css'
SRC='PITCHME.md'
OUTPUT='dist/index.html'
HOST='https://flutter-ffi-slide.done-sensuikan1973.com'

# See: https://github.com/marp-team/marp-cli#metadata
OG_TITLE='FlutterにおけるFFI'
OG_DESCRIPTION="「Flutter における FFI」at Flutter Meetup Tokyo"
OG_IMAGE="${HOST}/assets/icon.jpg"

# 出力先をクリア
rimraf 'dist'

# アセットをコピー
cpx 'assets/**/*.png' 'dist/assets'
cpx 'assets/**/*.jpg' 'dist/assets'
cpx 'assets/*.ico' 'dist/'

# NOTE: ローカルで作らないと文字化けしちゃうので、こうしてる。
# https://github.com/marp-team/marp-cli/blob/a410975992c3ea82dfe26c67b6b955cb142755dd/src/config.ts#L211 とかを見る感じ、
# lang 関連を設定すればいけそうな雰囲気あったが無理だった。残念。
cpx 'slide.pdf' 'dist/'

marp --html $SRC --output $OUTPUT \
--theme $THEME \
--title $OG_TITLE \
--description "$OG_DESCRIPTION" \
--url $HOST \
--og-image $OG_IMAGE
