 (* -*- mode: sml -*-
 * $Id: echo.sml,v 1.7 2003/02/09 17:20:00 sweeks Exp $
 * http://www.bagley.org/~doug/shootout/
 * from Tom 7
 *)

exception Error of string

val data = "Hello there sailor\n"
    
val num = 100

val (port, listener) =
  MLton.Socket.listen ()
  handle _ => raise Error ("Can't listen...\n")

fun server () =
    let val (_, _, ins, outs) = MLton.Socket.accept listener
        fun s b = 
            case TextIO.inputLine ins of
                "" => let in
                          Posix.Process.wait ();
                          print (concat ["server processed ",
					 Int.toString b,
					 " bytes\n"])
                      end
              | i =>  let in 
                          TextIO.output(outs, i);
			  TextIO.flushOut outs;
                          s (b + 19)
                      end
    in s 0
    end

fun client () =
    let
        val (ins, outs) = MLton.Socket.connect ("127.0.0.1", port)
        fun c 0 = let in
                      TextIO.closeOut outs;
                      TextIO.closeIn ins
                  end
          | c n = let in
                      TextIO.output(outs, data);
		      TextIO.flushOut outs;
                      TextIO.inputLine ins = data
                          orelse raise Error "Didn't receive the same data";
                      c (n - 1)
                  end
    in
        c num
    end

val _ = case Posix.Process.fork () of
    SOME pid => server ()
  | NONE => client ()

