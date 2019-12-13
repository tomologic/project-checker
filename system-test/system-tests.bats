setup () {
    # Bats provides a temporary directory in the BATS_TMPDIR variable
    # However it just points to the /tmp dir which means it can't be
    # removed at the teardown and it will not be empty as desired

    if [[ "${OSTYPE}" == "darwin"* ]]; then
        # OSX uses BSD mktemp and docker is only able to mount
        # directories from under /home so we create temporary
        # directory in project directory.
        BATS_TMP_DIR=$(mktemp -d "${PWD}/wrench-bats-system-test.XXXXXX")
    else
        # --suffix is only available in GNU mktemp
        BATS_TMP_DIR=$(mktemp -d --suffix -wrench-bats-system-test)
    fi

    export COMPOSE_FILE=${PWD}/docker-compose.yml
    pushd "${BATS_TMP_DIR}"
    git init
}

teardown () {
    # it is important to remove the temporary directory since some of the
    # tests assumes that the directory is empty at start
    popd
    rm -rf "${BATS_TMP_DIR}"
}


@test "Checks succeed for minimal project" {
    # create readme (must always be present)
    echo "% foo description" > README.md
    git add README.md

    run docker-compose run -v "${PWD}:/project" project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "Checks succeed for minimal project with untracked file with anomalies" {
    # create readme (must always be present)
    echo "% foo description" > README.md
    git add README.md

    # create untracked file with anomaly
    echo "with trailing whitespaces " > foo.txt

    run docker-compose run -v "${PWD}:/project" project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "Checks succeed when make file is present" {
    # create readme (must always be present)
    echo "% foo description" > README.md
    git add README.md

    # create valid Makefile (make files are allowed to have tabs)
    echo "foo:" > Makefile
    echo -e "\techo"m > Makefile
    git add Makefile

    run docker-compose run -v "${PWD}:/project" project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "Checks succeed for valid shell scripts" {
    # create readme (must always be present)
    echo "% foo description" > README.md
    git add README.md

    # create valid shell script
    echo "ls" > foo.sh
    git add foo.sh

    run docker-compose run -v "${PWD}:/project" project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "Check fails when readme file is absent" {
    run docker-compose run -v "${PWD}:/project" project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -ne 0 ]

    grep "ProjectAnomaly: Every project must include a README.md" <<< ${output}
}

@test "Check fails when there exists trailing whitespaces" {
    echo "% foo description with trailing whitespaces " > README.md
    git add README.md

    run docker-compose run -v "${PWD}:/project" project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -ne 0 ]

    grep "ProjectAnomaly: No file may have trailing whitespaces." <<< ${output}
}

@test "Check fails when there exists tabs" {
    echo -e "\t% foo description with tab" > README.md
    git add README.md

    run docker-compose run -v ${PWD}:/project project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -ne 0 ]
    grep "ProjectAnomaly: No files may have tabs." <<< ${output}
}

@test "Check fails when there exists files with no newline at end-of-file" {
    echo -e "% foo description with tab" > README.md
    git add README.md
    printf "a line without trailing linefeed" > foo.txt
    git add foo.txt

    run docker-compose run -v "${PWD}:/project" project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -ne 0 ]

    grep "ProjectAnomaly: All files must end with newline." <<< ${output}
}

@test "Check fails when there exists files with bash syntax errors" {
    echo -e "% foo description with tab" > README.md
    git add README.md

    echo -e "'" > foo.sh
    git add foo.sh

    run docker-compose run -v "${PWD}:/project" project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -ne 0 ]

    grep "ProjectAnomaly: All bash files must have correct syntax." <<< ${output}
}

@test "Check succeed when there exist tab anomalies in excluded directory" {
    mkdir foo
    echo -e "% Dummy readme." > README.md
    git add README.md

    echo -e "\tquux" > foo/bar.txt
    git add foo/bar.txt

    run docker-compose run -v "${PWD}:/project" project-checker \
        --exclude foo/*
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "Check succeed when there exist trailing whitespaces in excluded directory" {
    mkdir foo
    echo -e "% Dummy readme." > README.md
    git add README.md

    echo -e "quux " > foo/bar.txt
    git add foo/bar.txt
    run docker-compose run -v "${PWD}:/project" project-checker \
        --exclude foo/*
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "Check succeed when there exist trailing whitespaces in excluded sub directory" {
    mkdir -p foo/bar
    echo -e "% Dummy readme." > README.md
    git add README.md
    echo -e "quux " > foo/bar/baz.txt
    git add foo/bar/baz.txt
    run docker-compose run -v "${PWD}:/project" project-checker \
        --exclude foo/bar/*
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "Check succeed when there exist end-of-file anomalies in excluded directory" {
    mkdir foo
    echo -e "% Dummy readme." > README.md
    git add README.md
    printf "a line without trailing linefeed" > foo/bar.txt
    git add foo/bar.txt

    run docker-compose run -v "${PWD}:/project" project-checker \
        --exclude foo/*
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "Check succeed when there exist tab anomalies in multiple excluded directories" {
    mkdir foo
    mkdir qux
    echo -e "% Dummy readme." > README.md
    git add README.md

    echo -e "\tbaz " > foo/bar.txt
    git add foo/bar.txt
    echo -e "\tbaz " > qux/quux.txt
    git add qux/quux.txt

    run docker-compose run -v "${BATS_TMP_DIR}:/project" project-checker \
        --exclude foo/* \
        --exclude qux/*
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "Check succeed when there exist end-of-file anomalies in multiple excluded directories" {
    mkdir foo
    mkdir qux
    echo -e "% Dummy readme." > README.md
    git add README.md
    printf "a line without trailing linefeed" > foo/bar.txt
    git add foo/bar.txt
    printf "a line without trailing linefeed" > qux/quux.txt
    git add qux/quux.txt
    run docker-compose run -v "${PWD}:/project" project-checker \
        --exclude foo/* \
        --exclude qux/*
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}

@test "When a vulnerable package is in requirements.txt pip safety check should fail" {
    echo "Django==1.8.1" > requirements.txt
    git add requirements.txt
    run docker-compose run -v "${PWD}:/project" project-checker
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -ne 0 ]

    grep Django <<< ${output}
}

@test "Check that project with vulnerable packages succeeds if requirement file is excluded" {
    echo "Django==1.8.1" > requirements.txt
    echo -e "% Dummy readme." > README.md
    git add README.md
    git add requirements.txt
    run docker-compose run -v "${PWD}:/project" project-checker --exclude requirements.txt
    echo "output=$output"
    echo "status=$status"

    [ "${status}" -eq 0 ]
}
