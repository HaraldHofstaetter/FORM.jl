cd(dirname(@__FILE__))
download("https://github.com/vermaseren/form/releases/download/v4.1-20131025/form-4.1-x86_64-linux.tar.gz", "./form-4.1-x86_64-linux.tar.gz")
run(`tar xzvf form-4.1-x86_64-linux.tar.gz`)
run(`mv form-4.1-x86_64-linux/tform bin/`)
run(`mv form-4.1-x86_64-linux/form bin/`)
run(`rmdir form-4.1-x86_64-linux`)
run(`rm form-4.1-x86_64-linux.tar.gz`)

