#!/usr/bin/env bash

GOROOT=${1:-../go}
JSONROOT="."

# Check if the Go toolchain has a clean checkout.
if [ -n "$(cd $GOROOT; git status --porcelain)" ]; then
    (cd $GOROOT; git status --porcelain)
    echo "Working directory is not clean."
    echo ""
    echo "To cleanup, run:"
    echo "    (cd $GOROOT && git checkout . && git clean -fd)"
    exit 1
fi

/bin/rm -rf $GOROOT/src/encoding/json/*
cp $JSONROOT/v1/* $GOROOT/src/encoding/json/
cp -r $JSONROOT/internal/ $GOROOT/src/encoding/json/internal/
mkdir $GOROOT/src/encoding/json/v2/
cp -r $JSONROOT/*.go $GOROOT/src/encoding/json/v2/
mkdir $GOROOT/src/encoding/json/jsontext/
cp -r $JSONROOT/jsontext/*.go $GOROOT/src/encoding/json/jsontext/
find $GOROOT/src/encoding/json -type f -exec sed -i 's|github[.]com/go-json-experiment/json/v1|encoding/json|g' {} +
find $GOROOT/src/encoding/json -type f -exec sed -i 's|github[.]com/go-json-experiment/json/|encoding/json/|g' {} +
find $GOROOT/src/encoding/json -type f -exec sed -i 's|github[.]com/go-json-experiment/json|encoding/json/v2|g' {} +

# Adjust for changed package path.
sed -i 's/json\.struct/v2.struct/g' $GOROOT/src/encoding/json/v2/errors_test.go

# Adjust tests that hardcode formatted error strings.
sed -i 's/}`, "Time.UnmarshalJSON: input is not a JSON string/}`, "json: cannot unmarshal JSON object into Go type time.Time/g' $GOROOT/src/time/time_test.go
sed -i 's/]`, "Time.UnmarshalJSON: input is not a JSON string/]`, "json: cannot unmarshal JSON array into Go type time.Time/g' $GOROOT/src/time/time_test.go

# Adjust for changed dependency tree.
sed -i 's|encoding/json|encoding/json/v2|g' $GOROOT/src/cmd/go/internal/imports/scan_test.go
sed -i 's|encoding/binary|internal/reflectlite|g' $GOROOT/src/cmd/go/internal/imports/scan_test.go
LINE=$(sed -n '/encoding\/json, encoding\/pem, encoding\/xml, mime;/=' $GOROOT/src/go/build/deps_test.go)
sed -i 's|encoding/json, encoding/pem, encoding/xml, mime|encoding/pem, encoding/xml, mime|g' $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+ 1)) i\\\\"                                   $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+ 2)) i\\\tSTR, errors"                        $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+ 3)) i\\\t< encoding/json/internal"           $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+ 4)) i\\\t< encoding/json/internal/jsonflags" $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+ 5)) i\\\t< encoding/json/internal/jsonopts"  $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+ 6)) i\\\t< encoding/json/internal/jsonwire"  $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+ 7)) i\\\t< encoding/json/jsontext;"          $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+ 8)) i\\\\"                                   $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+ 9)) i\\\tFMT,"                               $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+10)) i\\\tencoding/hex,"                      $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+11)) i\\\tencoding/base32,"                   $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+12)) i\\\tencoding/base64,"                   $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+13)) i\\\tencoding/binary,"                   $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+14)) i\\\tencoding/json/jsontext,"            $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+15)) i\\\tencoding/json/internal,"            $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+16)) i\\\tencoding/json/internal/jsonflags,"  $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+17)) i\\\tencoding/json/internal/jsonopts,"   $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+18)) i\\\tencoding/json/internal/jsonwire"    $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+19)) i\\\t< encoding/json/v2"                 $GOROOT/src/go/build/deps_test.go
sed -i "$((LINE+20)) i\\\t< encoding/json;"                   $GOROOT/src/go/build/deps_test.go
LINE=$(sed -n '/Test-only packages can have anything they want/=' $GOROOT/src/go/build/deps_test.go)
sed -i "$((LINE+1)) i\\\tFMT, compress/gzip, embed, encoding/binary < encoding/json/internal/jsontest;" $GOROOT/src/go/build/deps_test.go

# Adjust for newly added API.
ISSUE=71497
FILE="next/$ISSUE.txt"
NEXT="$GOROOT/doc/next/6-stdlib/99-minor"
mkdir -p $NEXT/encoding/json
echo "A new [Options] type with associated constructors provide individual options" >> $NEXT/encoding/json/$ISSUE.md
echo "to configure \"encoding/json/v2\" to operate with certain historical v1 behavior." >> $NEXT/encoding/json/$ISSUE.md
echo "The [DefaultOptionsV2] option represents the set of all options needed" >> $NEXT/encoding/json/$ISSUE.md
echo "to configure \"encoding/json/v2\" to entirely operate with historical v1 behavior." >> $NEXT/encoding/json/$ISSUE.md
mkdir -p $NEXT/encoding/json/v2
echo "A new major version of \"encoding/json\" for processing JSON at a semantic level which is" >> $NEXT/encoding/json/v2/$ISSUE.md
echo "functionality that determines the meaning of JSON values as Go values and vice-versa." >> $NEXT/encoding/json/v2/$ISSUE.md
mkdir -p $NEXT/encoding/json/jsontext
echo "A new package to process JSON at a syntactic level that" >> $NEXT/encoding/json/jsontext/$ISSUE.md
echo "is concerned with processing JSON based on its grammar alone." >> $NEXT/encoding/json/jsontext/$ISSUE.md
NEXT="$GOROOT/api/next/$ISSUE.txt"
echo "pkg encoding/json, func CallMethodsWithLegacySemantics(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func DefaultOptionsV1() jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func EscapeInvalidUTF8(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func FormatBytesWithLegacySemantics(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func FormatTimeWithLegacySemantics(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func MatchCaseSensitiveDelimiter(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func MergeWithLegacySemantics(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func OmitEmptyWithLegacyDefinition(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func ReportErrorsWithLegacySemantics(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func StringifyWithLegacySemantics(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, func UnmarshalArrayFromAnyLength(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, method (*Number) UnmarshalJSONFrom(*jsontext.Decoder, jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json, method (*UnmarshalTypeError) Unwrap() error #$ISSUE" >> $NEXT
echo "pkg encoding/json, method (Number) MarshalJSONTo(*jsontext.Encoder, jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json, type Marshaler = json.Marshaler #$ISSUE" >> $NEXT
echo "pkg encoding/json, type Options = jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json, type RawMessage = jsontext.Value #$ISSUE" >> $NEXT
echo "pkg encoding/json, type UnmarshalTypeError struct, Err error #$ISSUE" >> $NEXT
echo "pkg encoding/json, type Unmarshaler = json.Unmarshaler #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func AllowDuplicateNames(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func AllowInvalidUTF8(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func AppendFormat([]uint8, []uint8, ...jsonopts.Options) ([]uint8, error) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func AppendQuote[\$0 interface{ ~[]uint8 | ~string }]([]uint8, \$0) ([]uint8, error) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func AppendUnquote[\$0 interface{ ~[]uint8 | ~string }]([]uint8, \$0) ([]uint8, error) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func Bool(bool) Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func CanonicalizeRawFloats(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func CanonicalizeRawInts(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func EscapeForHTML(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func EscapeForJS(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func Float(float64) Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func Int(int64) Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func Multiline(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func NewDecoder(io.Reader, ...jsonopts.Options) *Decoder #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func NewEncoder(io.Writer, ...jsonopts.Options) *Encoder #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func PreserveRawStrings(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func ReorderRawObjects(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func SpaceAfterColon(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func SpaceAfterComma(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func String(string) Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func Uint(uint64) Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func WithIndent(string) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, func WithIndentPrefix(string) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) InputOffset() int64 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) PeekKind() Kind #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) ReadToken() (Token, error) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) ReadValue() (Value, error) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) Reset(io.Reader, ...jsonopts.Options) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) SkipValue() error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) StackDepth() int #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) StackIndex(int) (Kind, int64) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) StackPointer() Pointer #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Decoder) UnreadBuffer() []uint8 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Encoder) OutputOffset() int64 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Encoder) Reset(io.Writer, ...jsonopts.Options) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Encoder) StackDepth() int #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Encoder) StackIndex(int) (Kind, int64) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Encoder) StackPointer() Pointer #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Encoder) UnusedBuffer() []uint8 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Encoder) WriteToken(Token) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Encoder) WriteValue(Value) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*SyntacticError) Error() string #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*SyntacticError) Unwrap() error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Value) Canonicalize(...jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Value) Compact(...jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Value) Format(...jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Value) Indent(...jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (*Value) UnmarshalJSON([]uint8) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Kind) String() string #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Pointer) AppendToken(string) Pointer #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Pointer) Contains(Pointer) bool #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Pointer) IsValid() bool #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Pointer) LastToken() string #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Pointer) Parent() Pointer #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Pointer) Tokens() iter.Seq[string] #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Token) Bool() bool #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Token) Clone() Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Token) Float() float64 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Token) Int() int64 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Token) Kind() Kind #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Token) String() string #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Token) Uint() uint64 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Value) Clone() Value #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Value) IsValid(...jsonopts.Options) bool #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Value) Kind() Kind #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Value) MarshalJSON() ([]uint8, error) #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, method (Value) String() string #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type Decoder struct #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type Encoder struct #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type Kind uint8 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type Options = jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type Pointer string #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type SyntacticError struct #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type SyntacticError struct, ByteOffset int64 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type SyntacticError struct, Err error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type SyntacticError struct, JSONPointer Pointer #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type Token struct #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, type Value []uint8 #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var BeginArray Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var BeginObject Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var EndArray Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var EndObject Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var ErrDuplicateName error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var ErrNonStringName error #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var False Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var Internal exporter #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var Null Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/jsontext, var True Token #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func DefaultOptionsV2() jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func Deterministic(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func DiscardUnknownMembers(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func FormatNilMapAsNull(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func FormatNilSliceAsNull(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func GetOption[\$0 interface{}](jsonopts.Options, func(\$0) jsonopts.Options) (\$0, bool) #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func JoinMarshalers(...*typedArshalers[jsontext.Encoder]) *typedArshalers[jsontext.Encoder] #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func JoinOptions(...jsonopts.Options) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func JoinUnmarshalers(...*typedArshalers[jsontext.Decoder]) *typedArshalers[jsontext.Decoder] #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func Marshal(interface{}, ...jsonopts.Options) ([]uint8, error) #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func MarshalEncode(*jsontext.Encoder, interface{}, ...jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func MarshalFunc[\$0 interface{}](func(\$0) ([]uint8, error)) *typedArshalers[jsontext.Encoder] #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func MarshalToFunc[\$0 interface{}](func(*jsontext.Encoder, \$0, jsonopts.Options) error) *typedArshalers[jsontext.Encoder] #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func MarshalWrite(io.Writer, interface{}, ...jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func MatchCaseInsensitiveNames(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func OmitZeroStructFields(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func RejectUnknownMembers(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func StringifyNumbers(bool) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func Unmarshal([]uint8, interface{}, ...jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func UnmarshalDecode(*jsontext.Decoder, interface{}, ...jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func UnmarshalFromFunc[\$0 interface{}](func(*jsontext.Decoder, \$0, jsonopts.Options) error) *typedArshalers[jsontext.Decoder] #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func UnmarshalFunc[\$0 interface{}](func([]uint8, \$0) error) *typedArshalers[jsontext.Decoder] #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func UnmarshalRead(io.Reader, interface{}, ...jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func WithMarshalers(*typedArshalers[jsontext.Encoder]) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, func WithUnmarshalers(*typedArshalers[jsontext.Decoder]) jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, method (*SemanticError) Error() string #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, method (*SemanticError) Unwrap() error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type Marshaler interface { MarshalJSON } #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type Marshaler interface, MarshalJSON() ([]uint8, error) #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type MarshalerTo interface { MarshalJSONTo } #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type MarshalerTo interface, MarshalJSONTo(*jsontext.Encoder, jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type Marshalers = typedArshalers[jsontext.Encoder] #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type Options = jsonopts.Options #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type SemanticError struct #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type SemanticError struct, ByteOffset int64 #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type SemanticError struct, Err error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type SemanticError struct, GoType reflect.Type #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type SemanticError struct, JSONKind jsontext.Kind #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type SemanticError struct, JSONPointer jsontext.Pointer #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type SemanticError struct, JSONValue jsontext.Value #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type Unmarshaler interface { UnmarshalJSON } #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type Unmarshaler interface, UnmarshalJSON([]uint8) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type UnmarshalerFrom interface { UnmarshalJSONFrom } #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type UnmarshalerFrom interface, UnmarshalJSONFrom(*jsontext.Decoder, jsonopts.Options) error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, type Unmarshalers = typedArshalers[jsontext.Decoder] #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, var ErrUnknownName error #$ISSUE" >> $NEXT
echo "pkg encoding/json/v2, var SkipFunc error #$ISSUE" >> $NEXT
# The following declarations were moved to encoding/json/v2 or encoding/json/jsontext.
EXCEPT="$GOROOT/api/except.txt"
echo "pkg encoding/json, method (*RawMessage) UnmarshalJSON([]uint8) error" >> $EXCEPT
echo "pkg encoding/json, method (RawMessage) MarshalJSON() ([]uint8, error)" >> $EXCEPT
echo "pkg encoding/json, type Marshaler interface { MarshalJSON }" >> $EXCEPT
echo "pkg encoding/json, type Marshaler interface, MarshalJSON() ([]uint8, error)" >> $EXCEPT
echo "pkg encoding/json, type RawMessage []uint8" >> $EXCEPT
echo "pkg encoding/json, type Unmarshaler interface { UnmarshalJSON }" >> $EXCEPT
echo "pkg encoding/json, type Unmarshaler interface, UnmarshalJSON([]uint8) error" >> $EXCEPT

# Run the tests.
(cd $GOROOT/src; ./all.bash)
