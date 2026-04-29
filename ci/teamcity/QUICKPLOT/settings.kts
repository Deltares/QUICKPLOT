import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.PullRequests
import jetbrains.buildServer.configs.kotlin.buildFeatures.commitStatusPublisher
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildFeatures.pullRequests
import jetbrains.buildServer.configs.kotlin.buildSteps.powerShell
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.failureConditions.BuildFailureOnMetric
import jetbrains.buildServer.configs.kotlin.failureConditions.BuildFailureOnText
import jetbrains.buildServer.configs.kotlin.failureConditions.failOnMetricChange
import jetbrains.buildServer.configs.kotlin.failureConditions.failOnText
import jetbrains.buildServer.configs.kotlin.triggers.VcsTrigger
import jetbrains.buildServer.configs.kotlin.triggers.finishBuildTrigger
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the

    mvnDebug org.jetbrains.teamcity:teamcity-configs-maven-plugin:generate

command and attach your debugger to the port 8000.

To debug in IntelliJ Idea, open the 'Maven Projects' tool window (View
-> Tool Windows -> Maven Projects), find the generate task node
(Plugins -> teamcity-configs -> teamcity-configs:generate), the
'Debug' option is available in the context menu for the task.
*/

version = "2025.11"

project {

    subProject(Windows)
    subProject(Linux)
}


object Linux : Project({
    name = "Linux"

    buildType(Linux_LnxQuickplotReleaseZip)
    buildType(Linux_LnxDetermineGitProperties)
    buildType(Linux_LnxBuildMexFiles)
    buildType(Linux_LnxCompileQuickplot)
    buildType(Linux_LnxRunQuickplotTestBenchStandalone)
    buildType(Linux_LnxRunQuickplotTestBenchWithinMatlab)
    buildTypesOrder = arrayListOf(Linux_LnxDetermineGitProperties, Linux_LnxRunQuickplotTestBenchWithinMatlab, Linux_LnxBuildMexFiles, Linux_LnxCompileQuickplot, Linux_LnxRunQuickplotTestBenchStandalone, Linux_LnxQuickplotReleaseZip)
})

object Linux_LnxBuildMexFiles : BuildType({
    name = "[lnx] Build mex files"

    artifactRules = """
        +:src/delft3d_matlab/private/exepath.mexa64
        +:src/delft3d_matlab/private/reducepoints.mexa64
    """.trimIndent()
    buildNumberPattern = "QP %build.vcs.number.MatlabTools_GithubQuickplot%"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Build mex files"
            id = "B"
            workingDir = "makefiles/"
            scriptContent = """
                #!/bin/bash
                echo Running in `pwd`
                
                echo -----------------------------------------
                . /usr/share/Modules/init/bash
                module use --append /opt/apps/modules
                
                echo -----------------------------------------
                echo Listing of available modules:
                module avail
                
                echo -----------------------------------------
                echo Activating matlab/2023b module:
                module load matlab/2023b
                
                echo -----------------------------------------
                echo Building mex files:
                matlab -batch make_mex
            """.trimIndent()
        }
    }

    features {
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
            }
        }
    }

    requirements {
        equals("teamcity.agent.jvm.os.name", "Linux")
        doesNotContain("teamcity.agent.jvm.os.version", "el9")
    }
})

object Linux_LnxCompileQuickplot : BuildType({
    name = "[lnx] Compile QUICKPLOT"

    artifactRules = """
        src/quickplot64/run_d3d_qp.sh => 64bit/
        src/quickplot64/d3d_qp => 64bit/
        src/quickplot64/d3d_qp.version => 64bit/
        src/quickplot64/netcdfAll-4.1.jar => 64bit/
        src/quickplot64/colormaps/* => 64bit/colormaps
        src/quickplot64/private/d3d_qp.png => 64bit/colormaps/
        src/delwaq2raster64/run_delwaq2raster.sh => 64bit/
        src/delwaq2raster64/delwaq2raster => 64bit/
        src/ecoplot64/run_ecoplot.sh => 64bit/
        src/ecoplot64/ecoplot => 64bit/
        src/sim2ugrid64/run_sim2ugrid.sh => 64bit/
        src/sim2ugrid64/sim2ugrid => 64bit/
        src/system_tests/hello_world => 64bit/
        src/system_tests/graphics_test => 64bit/
        src/system_tests/matlab_sysinfo => 64bit/
        src/system_tests/*.sh => 64bit/
    """.trimIndent()
    buildNumberPattern = "QP %build.vcs.number.MatlabTools_GithubQuickplot%"
    publishArtifacts = PublishMode.ALWAYS

    vcs {
        root(DslContext.settingsRoot)

        cleanCheckout = true
    }

    steps {
        script {
            name = "include mex files"
            id = "include_mex_files"
            scriptContent = """
                cp mex_files_linux/exepath.mexa64 src/delft3d_matlab/private
                cp mex_files_linux/reducepoints.mexa64 src/delft3d_matlab/private
            """.trimIndent()
        }
        script {
            name = "Run make_all in MATLAB"
            id = "Run_make_all_in_MATLAB"
            workingDir = "makefiles/"
            scriptContent = """
                #!/bin/bash
                . /usr/share/Modules/init/bash
                module use --append /opt/apps/modules
                module load matlab/2023b
                
                echo Running in `pwd`
                export TEAMCITY_BUILD_BRANCH="%teamcity.build.branch%"
                matlab -batch make_all
            """.trimIndent()
        }
    }

    failureConditions {
        executionTimeoutMin = 10
    }

    features {
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
            }
        }
    }

    dependencies {
        dependency(Linux_LnxBuildMexFiles) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:*=>mex_files_linux"
            }
        }
    }

    requirements {
        contains("teamcity.agent.jvm.os.name", "Linux")
        doesNotContain("teamcity.agent.jvm.os.version", "el9")
    }
})

object Linux_LnxDetermineGitProperties : BuildType({
    name = "[lnx] Determine Git properties"

    artifactRules = """
        +:gitsettings
    """.trimIndent()
    buildNumberPattern = "QP %build.vcs.number.MatlabTools_GithubQuickplot%"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Get Git properties"
            id = "Get_Git_properties"
            scriptContent = """
                ls -al
                echo "-- Git status --"
                git status
                echo "-- Git origin --"
                git remote get-url origin
                echo "-- Git branch --"
                git rev-parse --abbrev-ref HEAD
                echo "-- Git branch according TeamCity --"
                echo "%teamcity.build.branch%"
                echo "-- Git hash --"
                git rev-parse HEAD
                echo "-- Git short hash --"
                git rev-parse --short HEAD
                echo "-- writing gitsettings file --"
                echo "\\def\\@gitrepository{\\detokenize{`git remote get-url origin`}}" > gitsettings
                echo "\\def\\@gitbranch{\\detokenize{%teamcity.build.branch%}}" >> gitsettings
                echo "\\def\\@githashlong{\\detokenize{%build.revisions.revision%}}" >> gitsettings
                echo "\\def\\@githashshort{\\detokenize{%build.revisions.short%}}" >> gitsettings
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            branchFilter = """
                +pr: sourceRepo=same draft=false
                +:<default>
            """.trimIndent()
        }
    }

    features {
        perfmon {
        }
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
                ignoreDrafts = true
            }
        }
    }

    requirements {
        contains("teamcity.agent.jvm.os.name", "Linux")
    }
})

object Linux_LnxQuickplotReleaseZip : BuildType({
    name = "[lnx] QUICKPLOT Release zip"

    artifactRules = "QUICKPLOT*.zip"
    buildNumberPattern = "QP ${Windows_WinCompileQuickplot.depParamRefs["build.revisions.revision"]}"

    vcs {
        cleanCheckout = true
    }

    steps {
        script {
            name = "Collect all files for Delft3D FM zip-file"
            id = "Collect_all_files_for_Delft3D_FM_tgz_file"
            scriptContent = """
                #!/bin/bash
                
                # Need to get the first line of d3d_qp.version
                cd dist_delft3d4/bin
                full_version_string=${'$'}(head -n 1 d3d_qp.version)
                
                cd ../..
                echo full_version_string = ${'$'}full_version_string
                version_string=${'$'}{full_version_string:41:-22}
                echo version_string = ${'$'}version_string
                
                echo Creating folders ...
                name=QUICKPLOT\ ${'$'}version_string
                echo name = ${'$'}name
                mkdir -p "dist/${'$'}name/lnx64/quickplot/bin"
                mkdir -p "dist/${'$'}name/lnx64/manuals"
                mkdir -p "dist/${'$'}name/lnx64/delft3d_matlab"
                
                echo Copying files ...
                /bin/cp -rf dist_delft3d4/bin/* "dist/${'$'}name/lnx64/quickplot/bin/"
                /bin/cp -rf manuals/* "dist/${'$'}name/lnx64/manuals/"
                /bin/cp -rf delft3d_matlab/* "dist/${'$'}name/lnx64/delft3d_matlab/"
                
                echo Adjusting permissions ...
                cd "dist/${'$'}name/lnx64/quickplot/bin"
                chmod +x *.sh
                chmod +x d3d_qp delwaq2raster ecoplot sim2ugrid
                cd ../../../../..
                
                # Since the new MATLAB_Runtime_R2023b installer is over 4GB ... better not include it in each artifact.
                echo "Please download the Linux 64-bit R2023b (23.2) MATLAB Runtime installer from" > dist/README.txt
                echo "https://mathworks.com/products/compiler/matlab-runtime.html" >> dist/README.txt
            """.trimIndent()
        }
        script {
            name = "Create Delft3D FM zip-file called QUICKPLOT.zip"
            id = "Create_Delft3D_FM_tgz_file_called_QUICKPLOT_zip"
            scriptContent = """
                cd dist
                zip -r ../QUICKPLOT.zip *
                cd ..
            """.trimIndent()
        }
        script {
            name = "Rename QUICKPLOT.zip to version specific name"
            id = "Rename_QUICKPLOT_zip_to_version_specific_name"
            scriptContent = """
                #!/bin/bash
                
                # Need to get the first line of d3d_qp.version
                cd dist_delft3d4/bin
                full_version_string=${'$'}(head -n 1 d3d_qp.version)
                
                cd ../..
                echo full_version_string = ${'$'}full_version_string
                version_string=${'$'}{full_version_string:41:-22}
                echo version_string = ${'$'}version_string
                
                name=QUICKPLOT\ ${'$'}version_string
                echo name = ${'$'}name
                
                mv QUICKPLOT.zip "${'$'}name.zip"
                
                # list the files
                ls -l
            """.trimIndent()
        }
    }

    triggers {
        finishBuildTrigger {
            buildType = "${Linux_LnxRunQuickplotTestBenchStandalone.id}"
            successfulOnly = true
        }
    }

    dependencies {
        dependency(Linux_LnxCompileQuickplot) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:64bit=>dist_delft3d4/bin"
            }
        }
        snapshot(Linux_LnxRunQuickplotTestBenchStandalone) {
            onDependencyFailure = FailureAction.FAIL_TO_START
        }
        snapshot(Linux_LnxRunQuickplotTestBenchWithinMatlab) {
            onDependencyFailure = FailureAction.FAIL_TO_START
        }
        dependency(Windows_WinCompileQuickplot) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:delft3d_matlab=>delft3d_matlab"
            }
        }
        dependency(Windows_WinLatexManualGeneration) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }
            
            artifacts {
               artifactRules = "+:pdf/Delft3D*.pdf => manuals"
            }
        }
    }

    requirements {
        contains("teamcity.agent.jvm.os.name", "Linux")
    }
})

object Linux_LnxRunQuickplotTestBenchStandalone : BuildType({
    name = "[lnx] Run QUICKPLOT test bench (standalone)"

    artifactRules = """
        testbench/*.pdf
        testbench/**/*.tex => tex.zip
        testbench/**/work/* => diff.zip
    """.trimIndent()
    buildNumberPattern = "${Windows_WinCompileQuickplot.depParamRefs.buildNumber}"

    vcs {
        root(DslContext.settingsRoot, "+:. => code")
        root(AbsoluteId("Quickplot_DSCTestbenchTestsQuickplot"), "+:. => testbench")
        root(AbsoluteId("Quickplot_ReposDsCommon"), "+:. => common")

        checkoutMode = CheckoutMode.ON_SERVER
        cleanCheckout = true
    }

    steps {
        script {
            name = "Verify checkout and copy common"
            id = "Verify_checkout_and_copy_common"
            scriptContent = """
                #!/bin/bash
                echo Running in `pwd`
                
                echo ----- Listing of root folder -----------------------------------------------------------------------
                ls -l
                
                echo ----- Listing of QUICKPLOT folder ------------------------------------------------------------------
                ls -l quickplot
                
                echo ----- Listing of QUICKPLOT x64 folder --------------------------------------------------------------
                cd quickplot/x64
                chmod +x *.sh
                chmod +x d3d_qp delwaq2raster ecoplot sim2ugrid hello_world matlab_sysinfo graphics_test
                cd ../..
                ls -l quickplot/x64
                
                echo ----- Copy common to testbench\common --------------------------------------------------------------
                /bin/cp -rf common testbench/common
                
                echo ----- Listing of test bench folder -----------------------------------------------------------------
                ls -l testbench
                
                echo --------------------------------------------------------------
            """.trimIndent()
        }
        script {
            name = "Run system tests"
            id = "Run_system_tests"
            workingDir = "quickplot/x64"
            scriptContent = """
                #!/bin/bash
                echo The PATH is set to `pwd`
                echo ----------------
                echo Running Hello World ...
                ./run_hello_world.sh /opt/apps/matlab/2023b
                echo ----------------
                echo Running sysinfo ...
                ./run_matlab_sysinfo.sh /opt/apps/matlab/2023b
                echo ----------------
                echo Running graphics test ...
                ./run_graphics_test.sh /opt/apps/matlab/2023b
                echo ----------------
            """.trimIndent()
        }
        script {
            name = "Run QUICKPLOT test bench"
            id = "Run_QUICKPLOT_test_bench"
            workingDir = "quickplot/x64"
            scriptContent = """
                #!/bin/bash
                echo The PATH is set to `pwd`
                
                echo ----------------
                echo Removing diary ...
                rm -rf diary
                
                echo ----------------
                echo Starting QUICKPLOT ...
                ./run_d3d_qp.sh /opt/apps/matlab/2023b validation ../../testbench teamcity finish exit
                echo ... QUICKPLOT ended
                
                echo ----------------
                echo Printing diary ...
                cat diary
            """.trimIndent()
        }
        script {
            name = "Generate report"
            id = "Generate_report"
            executionMode = BuildStep.ExecutionMode.RUN_ON_FAILURE
            workingDir = "testbench"
            scriptContent = """
                #!/bin/bash
                . /usr/share/Modules/init/bash
                module use --append /opt/apps/modules
                module load texlive
                
                cp ../gitsettings/gitsettings .
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            quietPeriodMode = VcsTrigger.QuietPeriodMode.USE_CUSTOM
            quietPeriod = 60
            triggerRules = """
                -:root=Quickplot_DSCTestbenchTestsQuickplot:**
                -:root=Quickplot_ReposDsCommon:**
            """.trimIndent()

            branchFilter = """
                +pr: sourceRepo=same draft=false
                +:<default>
            """.trimIndent()
        }
    }

    failureConditions {
        executionTimeoutMin = 80
    }

    features {
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
                ignoreDrafts = true
            }
        }
        commitStatusPublisher {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            publisher = github {
                githubUrl = "https://api.github.com"
                authType = personalToken {
                    token = "%github_deltares-service-account_access_token%"
                }
            }
        }
    }

    dependencies {
        dependency(Linux_LnxCompileQuickplot) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "64bit/**=>quickplot/x64"
            }
        }
        dependency(Windows_WinCompileQuickplot) {
            snapshot {
            }

            artifacts {
                artifactRules = "delft3d_matlab/**=>quickplot/delft3d_matlab"
            }
        }
        dependency(Linux_LnxDetermineGitProperties) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:*=>gitsettings"
            }
        }
    }

    requirements {
        contains("teamcity.agent.jvm.os.name", "Linux")
        doesNotContain("teamcity.agent.jvm.os.version", "el9")
    }
})

object Linux_LnxRunQuickplotTestBenchWithinMatlab : BuildType({
    name = "[lnx] Run QUICKPLOT test bench (within MATLAB)"

    artifactRules = """
        testbench/*.pdf
        testbench/**/*.tex => tex.zip
        testbench/**/work/* => diff.zip
    """.trimIndent()
    buildNumberPattern = "Tests %build.vcs.number.Quickplot_DSCTestbenchTestsQuickplot%: QP %build.vcs.number.MatlabTools_GithubQuickplot%"

    vcs {
        root(DslContext.settingsRoot, "+:.=>code")
        root(AbsoluteId("Quickplot_DSCTestbenchTestsQuickplot"), "+:.=>testbench")
        root(AbsoluteId("Quickplot_ReposDsCommon"), "+:.=>common")

        checkoutMode = CheckoutMode.ON_SERVER
        cleanCheckout = true
    }

    steps {
        script {
            name = "Verify checkout and copy common"
            id = "Verify_checkout_and_copy_common"
            scriptContent = """
                #!/bin/bash
                . /usr/share/Modules/init/bash
                
                echo "##teamcity[testStarted name='listing root folder']"
                echo "Running in `pwd`"
                ls -al .
                echo "##teamcity[testFinished name='listing root folder']"

                # The following is necessary because the server-side Linux
                # checkout doesn't keep the Git meta data
                echo "##teamcity[testStarted name='clone code again']"
                echo "Step into code folder ..."
                cd code
                echo "Delete everything ..."
                find . -mindepth 1 -delete
                echo "Clone repository ..."
                git clone %vcsroot.MatlabTools_GithubQuickplot.url% .
                if [[ "%teamcity.build.branch%" == main ]]; then
                   echo "Working on main ..."
                elif [[ "%teamcity.build.branch%" == pull* ]]; then
                   echo "Fetch pull request %teamcity.build.branch% ..."
                   git fetch origin %teamcity.build.branch%:%teamcity.build.branch%
                else
                   echo "Fetch branch %teamcity.build.branch% ..."
                   git fetch origin %teamcity.build.branch%:%teamcity.build.branch%
                fi
                git checkout %teamcity.build.branch%
                echo "Step back to root folder ..."
                cd ..
                echo "##teamcity[testFinished name='clone code again']"
                
                echo "##teamcity[testStarted name='listing code folder']"
                ls -al code
                echo "##teamcity[testFinished name='listing code folder']"
                
                echo "##teamcity[testStarted name='listing quickplot folder']"
                ls -al code/src/delft3d_matlab
                echo "##teamcity[testFinished name='listing quickplot folder']"
                
                echo "##teamcity[testStarted name='listing private folder']"
                ls -al code/src/delft3d_matlab/private
                echo "##teamcity[testFinished name='listing private folder']"

                echo "##teamcity[testStarted name='listing third-party folder']"
                ls -al code/third_party
                echo "##teamcity[testFinished name='listing third-party folder']"
                
                echo "##teamcity[testStarted name='listing snctools folder']"
                ls -al code/third_party/snctools
                echo "##teamcity[testFinished name='listing snctools folder']"
                
                echo "##teamcity[testStarted name='listing mexnc folder']"
                ls -al code/third_party/mexnc
                echo "##teamcity[testFinished name='listing mexnc folder']"
                
                echo "##teamcity[testStarted name='environment variables']"
                set
                echo "##teamcity[testFinished name='environment variables']"
                                
                echo "##teamcity[testStarted name='copy common']"
                cp -r common testbench/common
                echo "##teamcity[testFinished name='copy common']"
                
                echo "##teamcity[testStarted name='listing testbench folder']"
                ls -al testbench
                echo "##teamcity[testFinished name='listing testbench folder']"
            """.trimIndent()
        }
        script {
            name = "Git precheck"
            id = "Git_precheck"
            workingDir = "code/src/delft3d_matlab/"
            scriptContent = """
                #!/bin/bash
                
                echo ----- Git log ----------------------------------------------------------------------------
                echo Running in `pwd`
                git -P log -n 1 -v --decorate
                
                echo ----- Git log ----------------------------------------------------------------------------
                cd ..
                echo Running in `pwd`
                git -P log -n 1 -v --decorate
                
                echo ----- Git log ----------------------------------------------------------------------------
                cd ..
                echo Running in `pwd`
                git -P log -n 1 -v --decorate
                
                echo ----- Listing ----------------------------------------------------------------------------
                echo Listing `pwd`
                ls -al

                echo ------------------------------------------------------------------------------------------
            """.trimIndent()
        }
        script {
            name = "Run QUICKPLOT test bench within MATLAB"
            id = "Run_QUICKPLOT_test_bench_within_MATLAB"
            workingDir = "code/src/delft3d_matlab/"
            scriptContent = """
                #!/bin/bash
                echo Running in `pwd`
                
                echo ----- Initialize bash ------------------------------------------------------------------------------
                . /usr/share/Modules/init/bash
                
                echo ----- Initialize MATLAB ----------------------------------------------------------------------------
                module use --append /opt/apps/modules
                module load matlab/2023b
                
                echo Running in `pwd`
                echo ----- Starting MATLAB ------------------------------------------------------------------------------
                echo qp_validate\(\'../../../testbench\'\) > run_testbench.m
                matlab -batch run_testbench
                echo ----- End of MATLAB --------------------------------------------------------------------------------
            """.trimIndent()
        }
        script {
            name = "Generate report"
            id = "Generate_report"
            executionMode = BuildStep.ExecutionMode.RUN_ON_FAILURE
            workingDir = "testbench"
            scriptContent = """
                #!/bin/bash
                . /usr/share/Modules/init/bash
                module use --append /opt/apps/modules
                module load texlive
                
                cp ../gitsettings/gitsettings .
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            quietPeriodMode = VcsTrigger.QuietPeriodMode.USE_CUSTOM
            quietPeriod = 60
            triggerRules = """
                -:root=Quickplot_DSCTestbenchTestsQuickplot:**
                -:root=Quickplot_ReposDsCommon:**
            """.trimIndent()

            branchFilter = """
                +pr: sourceRepo=same draft=false
                +:<default>
            """.trimIndent()
        }
    }

    failureConditions {
        executionTimeoutMin = 80
    }

    features {
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
                ignoreDrafts = true
            }
        }
        commitStatusPublisher {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            publisher = github {
                githubUrl = "https://api.github.com"
                authType = personalToken {
                    token = "%github_deltares-service-account_access_token%"
                }
            }
        }
    }

    dependencies {
        dependency(Linux_LnxDetermineGitProperties) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:*=>gitsettings"
            }
        }
    }

    requirements {
        contains("teamcity.agent.jvm.os.name", "Linux")
        doesNotContain("teamcity.agent.jvm.os.version", "el9")
    }
})


object Windows : Project({
    name = "Windows"

    buildType(Windows_WinRunQuickplotTestBenchStandalone)
    buildType(Windows_WinRunQuickplotTestBenchWithinMatlab)
    buildType(Windows_WinBuildQuickplotSplashScreen)
    buildType(Windows_WinCompileQuickplot)
    buildType(Windows_WinQuickplotReleaseZip)
    buildType(Windows_WinBuildMexFiles)
    buildType(Windows_WinLatexManualGeneration)
    buildType(Windows_WinUpdateOpenEarthToolsLink)
    buildTypesOrder = arrayListOf(Windows_WinRunQuickplotTestBenchWithinMatlab, Windows_WinBuildMexFiles, Windows_WinBuildQuickplotSplashScreen, Windows_WinCompileQuickplot, Windows_WinRunQuickplotTestBenchStandalone, Windows_WinQuickplotReleaseZip)
})


object Windows_WinLatexManualGeneration : BuildType({
    name = "[win] Latex Manual Generation"

    artifactRules = """
        +:docs/end-user-docs/matlab/Delft3D-MATLAB_UM.pdf => pdf
        +:docs/end-user-docs/quickplot/Delft3D-QUICKPLOT_UM.pdf => pdf
        +:docs/end-user-docs/matlab/Delft3D-MATLAB_UM.log => log
        +:docs/end-user-docs/quickplot/Delft3D-QUICKPLOT_UM.log => log
    """.trimIndent()
    buildNumberPattern = "QP ${DslContext.settingsRoot.paramRefs.buildVcsNumber}"

    vcs {
        root(DslContext.settingsRoot)
        root(AbsoluteId("MatlabTools_HttpsGithubComDeltaresLatexInstallation"), "+:. => deltares_latex")
        cleanCheckout = true
    }
    
    steps {
        script {
            name = "Install Deltares Latex tools"
            workingDir = """deltares_latex"""
            scriptContent = """
                echo -----------------------------------------------------
                echo Run install.bat ...
                call install.bat

                echo -----------------------------------------------------
                echo Run initexmf.exe ...
                initexmf.exe --admin --update-fndb

                echo -----------------------------------------------------
                echo Run miktexpm.exe ...
                miktexpm --admin --verbose --update
                
                echo -----------------------------------------------------
            """.trimIndent()
        }
        script {
            name = "Generate QUICKPLOT Manual"
            workingDir = """docs\end-user-docs\quickplot"""
            scriptContent = """
                copy ..\..\..\gitsettings\gitsettings .
                pdflatex -shell-escape -interaction=nonstopmode Delft3D-QUICKPLOT_UM
                pdflatex -shell-escape -interaction=nonstopmode Delft3D-QUICKPLOT_UM
                pdflatex -shell-escape -interaction=nonstopmode Delft3D-QUICKPLOT_UM
            """.trimIndent()
        }
        script {
            name = "Generate Delft3D-MATLAB Manual"
            executionMode = BuildStep.ExecutionMode.RUN_ON_FAILURE
            workingDir = """docs\end-user-docs\matlab"""
            scriptContent = """
                copy ..\..\..\gitsettings\gitsettings .
                pdflatex -shell-escape -interaction=nonstopmode Delft3D-MATLAB_UM
                bibtex Delft3D-MATLAB_UM
                pdflatex -shell-escape -interaction=nonstopmode Delft3D-MATLAB_UM
                pdflatex -shell-escape -interaction=nonstopmode Delft3D-MATLAB_UM
            """.trimIndent()
        }
    }

    failureConditions {
        failOnText {
            conditionType = BuildFailureOnText.ConditionType.REGEXP
            pattern = "Output written on Delft3D-QUICKPLOT_UM.pdf"
            failureMessage = "generation failed"
            reverse = true
        }
        failOnText {
            conditionType = BuildFailureOnText.ConditionType.CONTAINS
            pattern = "Output written on Delft3D-MATLAB_UM.pdf"
            failureMessage = "generation failed"
            reverse = true
        }
    }
    
    features {
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
            }
        }
    }

    dependencies {
        dependency(Linux_LnxDetermineGitProperties) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:*=>gitsettings"
            }
        }
    }
    
    requirements {
        startsWith("teamcity.agent.jvm.os.name", "Windows")
    }
})


object Windows_WinBuildMexFiles : BuildType({
    name = "[win] Build mex files"

    artifactRules = """
        +:src/delft3d_matlab/private/reducepoints.mexw64
        +:src/delft3d_matlab/private/writeavi.mexw64
        +:src/quickplot_splash_screen/finish/CloseSplashScreen.mexw64
    """.trimIndent()
    buildNumberPattern = "QP %build.vcs.number.MatlabTools_GithubQuickplot%"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Build mex files"
            id = "Build_mex_files"
            workingDir = """makefiles\"""
            scriptContent = """
                echo Running in %%cd%%
                "c:\Program Files\Matlab\R2023a\bin\matlab.exe" -batch make_mex
            """.trimIndent()
        }
    }

    features {
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
            }
        }
    }

    requirements {
        startsWith("teamcity.agent.jvm.os.name", "Windows")
        exists("VS2022")
    }
})

object Windows_WinBuildQuickplotSplashScreen : BuildType({
    name = "[win] Build QUICKPLOT splash screen"

    artifactRules = "+:src/quickplot_splash_screen/build/Release/*"
    buildNumberPattern = "QP %build.vcs.number.MatlabTools_GithubQuickplot%"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Build Splash Screen"
            id = "Build_Splash_Screen"
            workingDir = "src/quickplot_splash_screen"
            scriptContent = """
                rem Create subdirectory
                mkdir build
                
                rem Switch to subdirectory
                cd build
                
                rem Run CMake to create solution
                cmake ..
                
                rem Show a listing to verify that everything has worked fine up to here
                dir
                
                rem Run CMake build (Debug seems to be the default)
                cmake --build . --config Release
            """.trimIndent()
        }
    }

    features {
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
            }
        }
    }

    requirements {
        startsWith("teamcity.agent.jvm.os.name", "Windows")
        exists("VS2022")
    }
})

object Windows_WinCompileQuickplot : BuildType({
    name = "[win] Compile QUICKPLOT"

    artifactRules = """
        splash_screen/d3d_qp.exe => 64bit/
        src/quickplot64/d3d_qp.exec => 64bit/
        src/quickplot64/d3d_qp.version => 64bit/
        src/quickplot64/netcdfAll-4.1.jar => 64bit/
        src/quickplot64/colormaps/* => 64bit/colormaps
        src/quickplot64/private/d3d_qp.png => 64bit/private/
        src/delwaq2raster64/delwaq2raster.exe => 64bit/
        src/ecoplot64/ecoplot.exe => 64bit/
        src/sim2ugrid64/sim2ugrid.exe => 64bit/
        src/delft3d_matlab_release/**/* => delft3d_matlab
        src/system_tests/*.exe => 64bit_system_tests/
    """.trimIndent()
    buildNumberPattern = "QP %build.vcs.number.MatlabTools_GithubQuickplot%"
    maxRunningBuilds = 1

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        script {
            name = "Include mex files"
            id = "Include_mex_files"
            scriptContent = """
                copy /Y mex_files_windows\CloseSplashScreen.mexw64 src\delft3d_matlab\private
                copy /Y mex_files_linux\exepath.mexa64 src\delft3d_matlab\private
                copy /Y mex_files_linux\reducepoints.mexa64 src\delft3d_matlab\private
                copy /Y mex_files_windows\reducepoints.mexw64 src\delft3d_matlab\private
                copy /Y mex_files_windows\writeavi.mexw64 src\delft3d_matlab\private
            """.trimIndent()
        }
        script {
            name = "Run make_all in MATLAB"
            workingDir = """makefiles\"""
            scriptContent = """
                echo Running in %%cd%%
                set TEAMCITY_BUILD_BRANCH=%teamcity.build.branch%
                "c:\Program Files\Matlab\R2023a\bin\matlab.exe" -batch make_all
            """.trimIndent()
        }
    }

    failureConditions {
        executionTimeoutMin = 10
    }

    features {
        perfmon {
        }
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
            }
        }
    }

    dependencies {
        dependency(Linux_LnxBuildMexFiles) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:*=>mex_files_linux"
            }
        }
        dependency(Windows_WinBuildMexFiles) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:*=>mex_files_windows"
            }
        }
        dependency(Windows_WinBuildQuickplotSplashScreen) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:d3d_qp.exe=>splash_screen"
            }
        }
    }

    requirements {
        contains("teamcity.agent.jvm.os.name", "Windows")
    }
})

object Windows_WinQuickplotReleaseZip : BuildType({
    name = "[win] QUICKPLOT Release zip"

    artifactRules = "QUICKPLOT*.zip"
    buildNumberPattern = "QP ${Windows_WinCompileQuickplot.depParamRefs["build.vcs.number"]}"

    vcs {
        cleanCheckout = true
    }

    steps {
        script {
            name = "Merge signed bins into tree"
            scriptContent = """xcopy x64_signedbins dist_delft3d4\bin /S /R /Y"""
        }
        script {
            name = "Commit signed version to Delft3D 4 distribution repository"
            enabled = false
            scriptContent = """
                setlocal enableDelayedExpansion
                set /P full_version_string=<dist_delft3d4\bin\d3d_qp.version
                echo full_version_string = !full_version_string!
                set version_string=!full_version_string:~41,-30!
                echo version_string      = !version_string!
                svn commit dist_delft3d4 -m "Update Delft3D-QUICKPLOT (Windows 64bit, signed binaries) to version !version_string!" --username %svn_buildserver_write_username% --password %svn_buildserver_write_password% --no-auth-cache --non-interactive
            """.trimIndent()
        }
        script {
            name = "Collect all files for Delft3D FM zip-file"
            scriptContent = """
                setlocal enableDelayedExpansion
                rem Need to get the first line of d3d_qp.version
                cd dist_delft3d4\bin
                for /f "delims=" %%%i in (d3d_qp.version) do (
                  set "full_version_string=%%%i"
                  Goto :done
                )
                :done
                cd ..\..
                rem set /P full_version_string=<dist_delft3d4\bin\d3d_qp.version
                echo full_version_string = !full_version_string!
                set version_string=%full_version_string:~41,-22%
                echo version_string = !version_string!
                
                set name=QUICKPLOT !version_string!
                echo name = !name!
                mkdir "dist\!name!\win64\quickplot\bin"
                
                xcopy dist_delft3d4\bin "dist\!name!\win64\quickplot\bin\" /S /R /Y
                xcopy manuals "dist\!name!\win64\manuals\" /S /R /Y
                xcopy delft3d_matlab "dist\!name!\win64\delft3d_matlab\" /S /R /Y
                
                rem Since the new MATLAB_Runtime_R2023a installer is over 4GB ... better not include it in each artifact.
                echo "Please download the Windows 64-bit R2023a (9.14) MATLAB Runtime installer from" > dist\README.txt
                echo "https://mathworks.com/products/compiler/matlab-runtime.html" >> dist\README.txt
                rem net use p: \\directory.intra\Project %svn_buildserver_password% /user:DIRECTORY\%svn_buildserver_username%
                rem xcopy p:\delft3d\users\teamcity\QUICKPLOT\MCR_R2013b_win64_installer.exe dist /S /R /Y
                rem net use p: /delete
            """.trimIndent()
        }
        powerShell {
            name = """Create Delft3D FM zip-file called "QUICKPLOT.zip""""
            scriptMode = script {
                content = "Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('dist', 'QUICKPLOT.zip');"
            }
        }
        script {
            name = "Rename QUICKPLOT.zip to version specific name"
            scriptContent = """
                setlocal enableDelayedExpansion
                cd dist_delft3d4\bin
                for /f "delims=" %%%i in (d3d_qp.version) do (
                  set "full_version_string=%%%i"
                  Goto :done
                )
                :done
                cd ..\..
                rem set /P full_version_string=<dist_delft3d4\bin\d3d_qp.version
                echo full_version_string = !full_version_string!
                set version_string=%full_version_string:~41,-22%
                echo version_string = !version_string!
                
                set name=QUICKPLOT !version_string!
                echo name = !name!
                
                move QUICKPLOT.zip "!name!.zip"
            """.trimIndent()
        }
    }

    triggers {
        finishBuildTrigger {
            buildType = "${Windows_WinRunQuickplotTestBenchStandalone.id}"
            successfulOnly = true
        }
    }

    dependencies {
        snapshot(Windows_WinRunQuickplotTestBenchStandalone) {
            onDependencyFailure = FailureAction.FAIL_TO_START
        }
        snapshot(Windows_WinRunQuickplotTestBenchWithinMatlab) {
            onDependencyFailure = FailureAction.FAIL_TO_START
        }
        dependency(AbsoluteId("Quickplot_SigningQuickplot")) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "quickplot_x64_signedbins_*.zip!/x64 => x64_signedbins"
            }
        }
        dependency(Windows_WinLatexManualGeneration) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }
            
            artifacts {
               artifactRules = "+:pdf/Delft3D*.pdf => manuals"
            }
        }
        artifacts(Windows_WinCompileQuickplot) {
            artifactRules = """
                +:64bit=>dist_delft3d4/bin
                +:delft3d_matlab=>delft3d_matlab
            """.trimIndent()
        }
    }

    requirements {
        contains("teamcity.agent.jvm.os.name", "Windows")
    }
})

object Windows_WinRunQuickplotTestBenchStandalone : BuildType({
    name = "[win] Run QUICKPLOT test bench (standalone)"

    artifactRules = """
        testbench/*.pdf
        testbench/**/*.tex => tex.zip
        testbench/**/work/* => diff.zip
    """.trimIndent()
    buildNumberPattern = "${Windows_WinCompileQuickplot.depParamRefs.buildNumber}"

    vcs {
        root(DslContext.settingsRoot, "+:.=>code")
        root(AbsoluteId("Quickplot_DSCTestbenchTestsQuickplot"), "+:.=>testbench")
        root(AbsoluteId("Quickplot_ReposDsCommon"), "+:. => common")

        cleanCheckout = true
    }

    steps {
        script {
            name = "Verify checkout and copy common"
            scriptContent = """
                echo Running in %%cd%%
                echo ----- Listing of root folder -----------------------------------------------------------------------
                dir .
                echo ----- Listing of QUICKPLOT folder ------------------------------------------------------------------
                dir quickplot
                echo ----- Listing of QUICKPLOT x64 folder --------------------------------------------------------------
                dir quickplot\64bit
                echo ----- Copy common to testbench\common --------------------------------------------------------------
                xcopy common testbench\common\ /f /s /e
                echo ----- Listing of test bench folder -----------------------------------------------------------------
                dir testbench
                echo --------------------------------------------------------------
            """.trimIndent()
        }
        script {
            name = "Run system tests ..."
            id = "Run_system_tests"
            workingDir = """quickplot\64bit_system_tests"""
            scriptContent = """
                set SVGA_ALLOW_LLVMPIPE=0
                echo The SVGA_ALLOW_LLVMPIPE is set to %%SVGA_ALLOW_LLVMPIPE%%
                echo ----------------
                set PATH=c:\Program Files\MATLAB\R2023a\runtime\win64;%%PATH%%
                echo The PATH is set to %%PATH%%
                echo ----------------
                dir
                echo ----------------
                if exist hello_world.exe (
                   hello_world.exe
                ) else (
                   echo hello_world.exe is not found!
                )
                echo ----------------
                if exist matlab_sysinfo.exe (
                   matlab_sysinfo.exe
                ) else (
                   echo matlab_sysinfo.exe is not found!
                )
                echo ----------------
                if exist graphics_test.exe (
                   graphics_test.exe
                ) else (
                   echo graphics_test.exe is not found!
                )
                echo ----------------
            """.trimIndent()
        }
        script {
            name = "Run QUICKPLOT test bench"
            workingDir = """quickplot\64bit"""
            scriptContent = """
                set SVGA_ALLOW_LLVMPIPE=0
                echo The SVGA_ALLOW_LLVMPIPE is set to %%SVGA_ALLOW_LLVMPIPE%%
                echo ----------------
                set PATH=c:\Program Files\MATLAB\R2023a\runtime\win64;%%PATH%%
                echo The PATH is set to %%PATH%%
                echo ----------------
                if exist diary (
                   echo Removing diary ...
                   del diary
                   echo ----------------
                )
                echo Locating QUICKPLOT binary ...
                if exist d3d_qp.exe (
                   echo d3d_qp.exe is found!
                ) else (
                   echo d3d_qp.exe is not found!
                )
                if exist d3d_qp.exec (
                   echo d3d_qp.exec is found!
                ) else (
                   echo d3d_qp.exec is not found!
                )
                echo ----------------
                echo Starting QUICKPLOT ...
                start /wait d3d_qp.exec validation ..\..\testbench teamcity finish exit
                echo ... QUICKPLOT ended
                echo ----------------
                echo Printing diary ...
                type diary
            """.trimIndent()
        }
        script {
            name = "Generate report"
            workingDir = "testbench"
            scriptContent = """
                copy ..\gitsettings\gitsettings .
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            quietPeriodMode = VcsTrigger.QuietPeriodMode.USE_CUSTOM
            quietPeriod = 60
            triggerRules = """
                -:root=Quickplot_DSCTestbenchTestsQuickplot:**
                -:root=Quickplot_ReposDsCommon:**
            """.trimIndent()

            branchFilter = """
                +pr: sourceRepo=same draft=false
                +:<default>
            """.trimIndent()
        }
    }

    failureConditions {
        executionTimeoutMin = 80
        failOnMetricChange {
            metric = BuildFailureOnMetric.MetricType.TEST_COUNT
            threshold = 480
            units = BuildFailureOnMetric.MetricUnit.DEFAULT_UNIT
            comparison = BuildFailureOnMetric.MetricComparison.LESS
            compareTo = value()
        }
    }

    features {
        perfmon {
        }
        pullRequests {
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
                ignoreDrafts = true
            }
        }
        commitStatusPublisher {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            publisher = github {
                githubUrl = "https://api.github.com"
                authType = personalToken {
                    token = "%github_deltares-service-account_access_token%"
                }
            }
        }
    }

    dependencies {
        dependency(Windows_WinCompileQuickplot) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "**=>quickplot"
            }
        }
        dependency(Linux_LnxDetermineGitProperties) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:*=>gitsettings"
            }
        }
    }

    requirements {
        contains("teamcity.agent.jvm.os.name", "Windows")
    }
})

object Windows_WinRunQuickplotTestBenchWithinMatlab : BuildType({
    name = "[win] Run QUICKPLOT test bench (within MATLAB)"

    artifactRules = """
        testbench/*.pdf
        testbench/**/*.tex => tex.zip
        testbench/**/work/* => diff.zip
    """.trimIndent()
    buildNumberPattern = "Tests %build.vcs.number.Quickplot_DSCTestbenchTestsQuickplot%: QP %build.vcs.number.MatlabTools_GithubQuickplot%"

    vcs {
        root(DslContext.settingsRoot, "+:.=>code")
        root(AbsoluteId("Quickplot_DSCTestbenchTestsQuickplot"), "+:.=>testbench")
        root(AbsoluteId("Quickplot_ReposDsCommon"), "+:.=>common")

        cleanCheckout = true
    }

    steps {
        script {
            name = "Verify checkout and copy common"
            scriptContent = """
                echo Running in %%cd%%
                echo ----- Listing of environment -----------------------------------------------------------------------
                set
                
                echo ----- Listing of root folder -----------------------------------------------------------------------
                dir .
                echo ----- Listing of code folder -----------------------------------------------------------------------
                dir code
                echo ----- Listing of QUICKPLOT source folder -----------------------------------------------------------
                dir code\src\delft3d_matlab
                echo ----- Copy common to testbench\common --------------------------------------------------------------
                xcopy common testbench\common\ /f /s /e
                echo ----- Listing of test bench folder -----------------------------------------------------------------
                dir testbench
                echo --------------------------------------------------------------
            """.trimIndent()
        }
        script {
            name = "Run QUICKPLOT test bench within MATLAB"
            workingDir = """code\src\delft3d_matlab\"""
            scriptContent = """
                set SVGA_ALLOW_LLVMPIPE=0
                echo The SVGA_ALLOW_LLVMPIPE is set to %%SVGA_ALLOW_LLVMPIPE%%
                echo ----------------
                echo Running in %%cd%%
                echo ----- Starting MATLAB ------------------------------------------------------------------------------
                echo qp_validate('..\..\..\testbench') > run_testbench.m
                "c:\Program Files\Matlab\R2023a\bin\matlab.exe" -batch run_testbench
                echo ----- End of MATLAB --------------------------------------------------------------------------------
            """.trimIndent()
        }
        script {
            name = "Generate report"
            executionMode = BuildStep.ExecutionMode.RUN_ON_FAILURE
            workingDir = "testbench"
            scriptContent = """
                copy ..\gitsettings\gitsettings .
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
                pdflatex -shell-escape -interaction=nonstopmode "validation_log.tex"
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            quietPeriodMode = VcsTrigger.QuietPeriodMode.USE_CUSTOM
            quietPeriod = 60
            triggerRules = """
                -:root=Quickplot_DSCTestbenchTestsQuickplot:**
                -:root=Quickplot_ReposDsCommon:**
            """.trimIndent()

            branchFilter = """
                +pr: sourceRepo=same draft=false
                +:<default>
            """.trimIndent()
        }
    }

    failureConditions {
        executionTimeoutMin = 80
        failOnMetricChange {
            metric = BuildFailureOnMetric.MetricType.TEST_COUNT
            threshold = 20
            units = BuildFailureOnMetric.MetricUnit.PERCENTS
            comparison = BuildFailureOnMetric.MetricComparison.LESS
            compareTo = build {
                buildRule = lastSuccessful()
            }
        }
    }

    features {
        perfmon {
        }
        pullRequests {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            provider = github {
                authType = token {
                    token = "%github_deltares-service-account_access_token%"
                }
                filterAuthorRole = PullRequests.GitHubRoleFilter.MEMBER
                ignoreDrafts = true
            }
        }
        commitStatusPublisher {
            vcsRootExtId = "MatlabTools_GithubQuickplot"
            publisher = github {
                githubUrl = "https://api.github.com"
                authType = personalToken {
                    token = "%github_deltares-service-account_access_token%"
                }
            }
        }
    }

    dependencies {
        dependency(Linux_LnxDetermineGitProperties) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }

            artifacts {
                artifactRules = "+:*=>gitsettings"
            }
        }
    }

    requirements {
        contains("teamcity.agent.jvm.os.name", "Windows")
    }
})

object Windows_WinUpdateOpenEarthToolsLink : BuildType({
    name = "[win] Update OpenEarthTools link"

    buildNumberPattern = "QP %build.vcs.number.MatlabTools_GithubQuickplot%"

    vcs {
        root(DslContext.settingsRoot)

        checkoutMode = CheckoutMode.MANUAL
        cleanCheckout = true
    }

    steps {
        script {
            name = "Update OpenEarth"
            id = "Clone_OpenEarth"
            scriptContent = """
                echo "Listing current folder:"
                dir
                echo "------------"
                git clone https://github.com/openearth/matlab-tools .
                echo "------------"
            """.trimIndent()
        }
        script {
            name = "Update QUICKPLOT submodule"
            id = "Update_QUICKPLOT_include"
            scriptContent = """
                git submodule update --init --recursive --remote
                echo "------------"
                echo "Listing current folder:"
                dir
                echo "------------"
                echo "Git status:"
                git status
            """.trimIndent()
        }
        script {
            name = "Commit change"
            id = "Commit_change"
            scriptContent = """
                git config user.name "SVC TeamCity Ansible"
                if [ -n "$(git status --porcelain)" ]; then
                    git commit -a -m "Updating Delft3D-MATLAB include to %build.vcs.number.MatlabTools_GithubQuickplot%"
                else
                    echo "No changes to commit."
                fi
            """.trimIndent()
        }
        script {
            name = "Push change"
            id = "Push_change"
            scriptContent = """
                set "ASKPASS=%teamcity.build.tempDir%\git-askpass-openearth.cmd"
                (
                    echo @echo off
                    echo if "%%~1"=="Username for 'https://github.com':" ^(
                    echo     echo x-access-token
                    echo ^) else ^(
                    echo     echo %github_openearth_matlabtools_commit_access_token%
                    echo ^)
                ) > "%ASKPASS%"
                set "GIT_ASKPASS=%ASKPASS%"
                set "GIT_TERMINAL_PROMPT=0"
                git push origin HEAD
                del "%ASKPASS%"
            """.trimIndent()
        }
    }

    triggers {
        finishBuildTrigger {
            buildType = "${Windows_WinQuickplotReleaseZip.id}"
            successfulOnly = true

            enforceCleanCheckout = true
        }
    }
})
