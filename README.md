# QUICKPLOT and Delft3D-MATLAB interface
QUICKPLOT is a post processing tool for the [Delft3D 4](https://www.deltares.nl/en/software-and-data/products/delft3d-4-suite) and [Delft3D FM](https://www.deltares.nl/en/software-and-data/products/delft3d-flexible-mesh-suite) Suites developed by [Deltares](https://www.deltares.nl/en).
It has been programmed in the [MATLAB](https://nl.mathworks.com/products/matlab.html) language and the source also functions as the Delft3D-MATLAB interface for working with Delft3D data from within the MATLAB environment.
QUICKPLOT does not only support Delft3D data files but a wide variety of other file formats that one may encounter in environmental modelling.
For details, see the [QUICKPLOT user manual](https://content.oss.deltares.nl/delft3d4/Delft3D-QUICKPLOT_User_Manual.pdf) and the [Delft3D-MATLAB user manual](https://content.oss.deltares.nl/delft3d4/Delft3D-MATLAB_User_Manual.pdf).

<div align="center">
<img src="src/tools_lgpl/matlab/quickplot/progsrc/private/d3d_qp.png" width="20%">
</div>

# Repository structure
[Link](https://github.com/Deltares/QUICKPLOT) to the main source code repository.
The repository contains six folders:
- `src` contains the source code. In particular the folder `src/delft3d_matlab` can act as a pre-release version of the Delft3D-MATLAB interfce and it represents the MATLAB source of QUICKPLOT. The `src` folder also includes: `quickplot_splash_screen` (for the C++ code handling the splash screen logic used on Windows), `system_tests` (for three small programs useful for identifying runtime issues when QUICKPLOT fails to start), and a folder `to_be_moved` containing some other MATLAB code unrelated to QUICKPLOT and the Delft3D-MATLAB interface.
- `makefiles` contains the files used forcreating the stand alone QUICKPLOT, and the release versions of the Delft3D-MATLAB interface.
- `docs` contains the end user documentation: the LaTeX source files of QUICKPLOT and Delft3D-MATLAB user manuals.
- `third_party` contains the files of some third party libraries used by QUICKPLOT and Delft3D-MATLAB for netCDF and drag-and-drop support.
- `ci` contains the configuration of our in-house TeamCity CI/CD pipeline.
- `.github` contains a workflow for backing up the GitHub repository to an internal GitLab repository, and a template for pull requests.

# License
The QUICKPLOT source code is governed by [LGPL 2.1 or later](LICENSE).

# Related repositories
- [OpenEarth MATLAB Tools](https://github.com/openearth/matlab-tools)
- [Delft3D](https://github.com/Deltares/Delft3D)
