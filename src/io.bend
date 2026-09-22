# File output helpers.
import Base

def close_pair(r: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (f, res) = r
  do IO<Unit>:
    File.close(f)
    IO.pass(Unit, res)

def write_file(+path: String, data: String) -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path, "w"))
    r : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, data)
    close_pair(r)
    IO.print("wrote " ++ path)
