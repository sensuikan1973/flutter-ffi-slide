THEME='themes/sensuikan1973_theme.css'
SRC='slide.md'
HTML_OUTPUT='dist/index.html'
PDF_OUTPUT='dist/flutter_ffi_slide_sensuikan1973.pdf'
HOST='https://flutter-ffi-slide.done-sensuikan1973.com'

# See: https://github.com/marp-team/marp-cli#metadata
OG_TITLE='FlutterにおけるFFI'
OG_DESCRIPTION="「FFIにおけるFlutter」 at Flutter Meetup Tokyo"
OG_IMAGE="${HOST}/assets/icon.jpg"

# 出力先をクリア
rimraf 'dist'

# アセットをコピー
cpx 'assets/**/*' 'dist/assets'

# HTML
marp --html $SRC --output $HTML_OUTPUT \
--theme $THEME \
--title $OG_TITLE \
--description "$OG_DESCRIPTION" \
--url $OG_URL \
--og-image $OG_IMAGE

# PDF
marp --html $SRC --pdf --allow-local-files --output $PDF_OUTPUT \
--theme $THEME \
--title $OG_TITLE \
--description $OG_DESCRIPTION \
--url $HOST \
--og-image $OG_IMAGE
