{;; Enables verbose notifications from nfnl, including notifications about
 ;; when it starts up and when it compiles successfully. Useful for debugging
 ;; the plugin itself and checking that it's running when you expect it to.
 :verbose false

 ;; When false, will not write the protective `-- [nfnl] ...` header to the resulting .lua files.
 ;; It will also prevent nfnl from checking for this header before overwriting .lua files.
 ;; Intended for users who wish to write shebang comments at the top of their .lua for easier execution.
 :header-comment true

 :orphan-detection
 {;; Automatically invoke :NfnlFindOrphans whenever you write to a .fnl file. This acts as a passive
  ;; garbage collection check and will warn you about dangling .lua files left over from .fnl deletions or renames.
  ;; If an orphan is found, you can use :NfnlDeleteOrphans to delete all of the files listed
  ;; automatically. The deletion command will NOT prompt you, so make sure you check the list first!
  :auto? true

  ;; If you embed nfnl, for example, in your Lua directory then nfnl will detect those files as orphans.
  ;; You can add Lua patterns here to tell nfnl which Lua paths are okay and should not be counted as orphans.
  ;; Example: ["lua/nfnl/"]
  :ignore-patterns []}

 ;; Passed to fennel.compileString when your code is compiled.
 ;; See https://fennel-lang.org/api for more information.
 :compiler-options {;; Disables ansi escape sequences in compiler output.
                    :error-pinpoint false}

 ;; Warning! In reality these paths are absolute and set to the root directory
 ;; of your project (where your .nfnl.fnl file is). This means even if you
 ;; open a .fnl file from outside your project's cwd the compiler will still
 ;; find your macro files. If you use relative paths like I'm demonstrating here
 ;; then macros will only work if your cwd is in the project you're working on.

 ;; They also use OS specific path separators, what you see below is just an example really.
 ;; I'm not including nfnl's directory from your runtimepath, but it would be there by default.
 ;; See :rtp-patterns below for more information on including other plugins in your path.

 ;; String to set the compiler's fennel.path to before compilation.
 :fennel-path "/home/.../?.fnlm;/home/.../?/init.fnlm;/home/.../fnl/?.fnlm;/home/.../fnl/?/init.fnlm;/home/.../?.fnl;/home/.../?/init.fnl;/home/.../?/init-macros.fnl;/home/.../fnl/?.fnl;/home/.../fnl/?/init.fnl;/home/.../fnl/?/init-macros.fnl"

 ;; String to set the compiler's fennel.macro-path to before compilation.
 :fennel-macro-path "/home/.../?.fnlm;/home/.../?/init.fnlm;/home/.../fnl/?.fnlm;/home/.../fnl/?/init.fnlm;/home/.../?.fnl;/home/.../?/init.fnl;/home/.../?/init-macros.fnl;/home/.../fnl/?.fnl;/home/.../fnl/?/init.fnl;/home/.../fnl/?/init-macros.fnl"

 ;; A list of glob patterns (autocmd pattern syntax) of files that
 ;; should be compiled. This is used as configuration for the BufWritePost
 ;; autocmd, so it'll only apply to buffers you're interested in.
 ;; Will use backslashes on Windows.
 ;; Defaults to compiling all .fnl files, you may want to limit it to your fnl/ directory.
 :source-file-patterns ["fnl/**/*.fnl"]
}
