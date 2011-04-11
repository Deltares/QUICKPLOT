switch computer
    otherwise
        if isunix
            appopt={'-m'}; % add '-C' to keep ctf in separate file
        else
            appopt={'-e'};
        end
        if matlabversionnumber>=7.04
           cleanup({'*_r13_6p5.*'})
        end
        mcc(appopt{:},'-a','./units.ini','-a','./qp_icons.mat','-a','./grib','-v','ecoplot.m','wl_identification.c')
end