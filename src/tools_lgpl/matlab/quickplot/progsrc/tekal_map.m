function varargout=tekal_map(cmd,varargin)

%  tekal_map      read/write tekal map file such that it can be plotted by muppet
%
%  example tekal_map('write',test.map,Data) writes the structure Data to a Tekal map map
%          Data is a structuture containing multiple blocks, each block contains:
%          Data(i_block).Blckname: Name of this data block (optional)
%          Data(i_block).Comments: Cell array of comment lines to be written to the map file (optional)
%          Data(i_block).X       : mmax * nmax X-Coordinates
%          Data(i_block).Y       : mmax * nmax Y-Coordinates
%          Data(i_block).Values  : mmax * nmax * nr_values acctual values to be written to the map file

fname   = varargin{1};

%% Switch read/write/new

switch lower(cmd)

%% Reading (to implement yet)
case 'read'


%% Writing
case 'write'

    fid = fopen(fname,'w+');

    Data = varargin{2};
    nr_blocks = length(Data);

    %% Cycle over number of blocks
    for i_block = 1: nr_blocks

        %% Get general information
        mmax     = size(Data(i_block).XComp,1);
        nmax     = size(Data(i_block).XComp,2);
        nr_dims  = length(size(Data(i_block).Values));
        if nr_dims == 2
            nr_values = 1;
        else
            nr_values = size(Data(i_block).Values,3);
        end

        %% Write the general information
        if simona2mdf_fieldandvalue(Data(i_block),'Comments')
            for i_comm = 1: length(Data(i_block).Comments)
                fprintf(fid,'%s \n',Data(i_block).Comments{i_comm});
            end
        end
        if simona2mdf_fieldandvalue(Data(i_block),'Blckname')
            fprintf(fid,'%s \n',Data(i_block).Blckname);
        else
            fprintf(fid,'B%3.3i \n',nr_block);
        end
        fprintf (fid,'%5i %5i %5i %5i \n',mmax*nmax,2 + nr_values,nmax,mmax);

        %% write the data
        format = ['%12.3f %12.3f ' repmat('%12.6f ',1,nr_values) '\n'];

        for m = 1: mmax
            for n = 1:nmax
                fprintf(fid,format,Data(i_block).X(m,n),Data(i_block).Y(m,n), ...
                                   Data(i_block).Values(m,n,:));
           end
        end
    end
    fclose (fid);

end
