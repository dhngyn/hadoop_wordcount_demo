if command -v python3 >/dev/null 2>&1; then
  exec python3 "$@"
elif command -v python >/dev/null 2>&1; then
  exec python "$@"
else
  echo "Khong tim thay python3 hoac python tren node nay" >&2
  exit 127
fi
