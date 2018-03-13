cd(dirname(@__FILE__))
download("https://github.com/vermaseren/form/releases/download/v4.2.0/form-4.2.0-x86_64-linux.tar.gz", "./form-4.2.0-x86_64-linux.tar.gz")
run(`tar xzvf form-4.2.0-x86_64-linux.tar.gz`)
run(`mv form-4.2.0-x86_64-linux/tform bin/`)
run(`mv form-4.2.0-x86_64-linux/form bin/`)
run(`rmdir form-4.2.0-x86_64-linux`)
run(`rm form-4.2.0-x86_64-linux.tar.gz`)

