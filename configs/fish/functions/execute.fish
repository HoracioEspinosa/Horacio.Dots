function execute --description "Run a command only if its binary is on PATH"
    if test (count $argv) -eq 0
        return 0
    end

    if which $argv[1] > /dev/null
        eval $argv
        return $status
    else
        return 1
    end
end
