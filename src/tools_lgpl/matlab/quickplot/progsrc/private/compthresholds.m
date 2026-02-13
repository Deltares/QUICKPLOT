function [Thresholds, InRange] = compthresholds(Ops, minmax_data, classes_between_thresholds)
%COMPTHRESHOLDS Determine automatic threshold levels.
%   THRESHOLDS = COMPTHRESHOLDS(OPS,LIMITS,BETWEEN) determines the
%   threshold levels. OPS is a data structure. LIMITS is an array of length
%   2 specifying the minimum and maximum value of the data to be plotted,
%   and BETWEEN = 0 if the thresholds themselves will be used (to draw
%   contours) and 1 if the ranges between the thresholds represent the
%   classes (e.g. contour patches). The following fields of OPS will be
%   used:
%
%       threshold: user specification of the thresholds. This may be
%                  * empty: default to 10 thresholds
%                  * integer: use the specified number of thresholds
%                  * data structure with one field: 'step': use the
%                    specified step between thresholds
%                  * vector: use the specified thresholds
%       thresholddistribution: 'logarithmic','anti-logarithmic','linear'
%       colourlimits: user specified colour range. This may be
%                  * empty: use the data range
%                  * array of length 2 specifying minimum and maximum
%                    values to be used
%       symmetriccolourlimits: logical

%----- LGPL --------------------------------------------------------------------
%
%   Copyright (C) 2011-2025 Stichting Deltares.
%
%   This library is free software; you can redistribute it and/or
%   modify it under the terms of the GNU Lesser General Public
%   License as published by the Free Software Foundation version 2.1.
%
%   This library is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%   Lesser General Public License for more details.
%
%   You should have received a copy of the GNU Lesser General Public
%   License along with this library; if not, see <http://www.gnu.org/licenses/>.
%
%   contact: delft3d.support@deltares.nl
%   Stichting Deltares
%   P.O. Box 177
%   2600 MH Delft, The Netherlands
%
%   All indications and logos of, and references to, "Delft3D" and "Deltares"
%   are registered trademarks of Stichting Deltares, and remain the property of
%   Stichting Deltares. All rights reserved.
%
%-------------------------------------------------------------------------------
%   http://www.deltaressystems.com
%   $HeadURL$
%   $Id$

% use 10 Thresholds if nothing specified
Thresholds = Ops.thresholds;
if isempty(Thresholds)
    Thresholds = 10;
end

% use colour limits if provided
if ~isempty(Ops.colourlimits)
    minmax = Ops.colourlimits;
    if isstruct(Thresholds) || is_positive_integer(Thresholds)
        if any(~isfinite(minmax))
            ui_message('warning','Infinite colour limits are not allowed when specifying only the number of thresholds or threshold step; using data range instead.')
            minmax = minmax_data;
        end
    end
else
    minmax = minmax_data;
end

% use symmetric limits if requested
if Ops.symmetriccolourlimits
    minmax = [-1 1] * max(abs(minmax));
end
% broaden the range slightly to make sure that all values are within the
% range
if abs(minmax(1)) > eps(0)*1e6 && isfinite(minmax(1))
    minmax(1) = minmax(1) - eps(minmax(1));
end
if abs(minmax(end)) > eps(0)*1e6 && isfinite(minmax(end))
    minmax(end) = minmax(end) + eps(minmax(end));
end

if isstruct(Thresholds) % Threshold step given
    thresholdsBasedOnMinmax = true;

    step = Thresholds.step;
    Thresholds = step*(floor(minmax(1)/step):ceil(minmax(2)/step));
    Thresholds([1, end]) = minmax;

elseif is_positive_integer(Thresholds) % number of Thresholds given
    thresholdsBasedOnMinmax = true;

    % transform to linear 
    if classes_between_thresholds
        LocStartClass = 0;
        LocEndClass = Thresholds+1;
    else
        LocStartClass = 1;
        LocEndClass = Thresholds;
    end
    ratio = (LocStartClass:LocEndClass)/(Thresholds+1);
    sign = 1;
    switch Ops.thresholddistribution
        case 'logarithmic'
            if all(minmax > 0)
                minmax = log10(minmax);
            elseif all(minmax < 0)
                minmax = log10(fliplr(-minmax)); % do as if positive
                ratio = fliplr(ratio); % reverse threshold order from large to small
                sign = -1; % convert back to negative
            else
                ui_message('warning','The colour limits have different sign: switching to linear distribution of thresholds')
                Ops.thresholddistribution = 'linear';
            end
        case 'linear'
            % nothing to do
        otherwise
            ui_message('warning','Unknown distribution "%s" using linear.', Ops.thresholddistribution)
            Ops.thresholddistribution = 'linear';
    end
    % generate thresholds
    Thresholds = minmax(1) + (minmax(2) - minmax(1)) * ratio;
    % transform back
    switch Ops.thresholddistribution
        case 'logarithmic'
            Thresholds = sign * 10.^Thresholds;
        case 'linear'
            % nothing to do
        otherwise
            error('Unknown distribution "%s" in back transformation.', Ops.thresholddistribution)
    end

else % actual Thresholds given
    thresholdsBasedOnMinmax = false;

    % use colour limits if provided
    if ~isempty(Ops.colourlimits) && isfield(Ops,'climclipping') && Ops.climclipping
        Thresholds(Thresholds < Ops.colourlimits(1) | Thresholds > Ops.colourlimits(2)) = [];
        if Thresholds(1) > Ops.colourlimits(1)
            Thresholds = [Ops.colourlimits(1), Thresholds];
        end
        if Thresholds(end) < Ops.colourlimits(2)
            Thresholds(end+1) = Ops.colourlimits(2);
        end
    end
end

if ~classes_between_thresholds
    % don't need to do anything
    InRange = true(size(Thresholds));

elseif ~isempty(Ops.colourlimits)
    if isempty(Thresholds)
        Thresholds = [-inf, Ops.colourlimits, inf];
        InRange = [false, true, false];
    else
        InRange = true(1,length(Thresholds)-1);
        if Thresholds(1) > Ops.colourlimits(1)
            if isfinite(Ops.colourlimits(1))
                Thresholds = [-inf, Ops.colourlimits(1), Thresholds];
                InRange = [false, true, InRange];
            else
                Thresholds = [-inf, Thresholds];
                InRange = [true, InRange];
            end
        elseif isfinite(Thresholds(1))
            Thresholds = [-inf, Thresholds];
            InRange = [false, InRange];
        end
        if Thresholds(end) < Ops.colourlimits(2)
            if isfinite(Ops.colourlimits(2))
                Thresholds = [Thresholds, Ops.colourlimits(2), inf];
                InRange = [InRange, true, false];
            else
                Thresholds = [Thresholds, inf];
                InRange = [InRange, true];
            end
        elseif isfinite(Thresholds(end))
            Thresholds = [Thresholds, inf];
            InRange = [InRange, false];
        end
    end

    if ~isfield(Ops,'climclipping') || ~Ops.climclipping
        InRange(:) = true;
    end

else % no colour limits set, thus we depend on the dynamics data limits
    % There are no data value smaller than minmax(1) and larger than
    % minmax(2).
    if isempty(Thresholds)
        Thresholds = minmax;
    else
        if minmax(1) < Thresholds(1)
            Thresholds = [minmax(1), Thresholds];
        elseif isfinite(Thresholds(1)) && ~thresholdsBasedOnMinmax
            Thresholds = [-inf, Thresholds];
        else
            % Thresholds(1) is already equal to -inf or minmax(1)
        end
        if minmax(2) > Thresholds(end)
            Thresholds = [Thresholds, minmax(2)];
        elseif isfinite(Thresholds(end)) && ~thresholdsBasedOnMinmax
            Thresholds = [Thresholds, inf];
        else
            % Thresholds(end) is already equal to inf or minmax(2)
        end
    end
    InRange = true(1,length(Thresholds)-1);
end


function bool = is_positive_integer(value)
if isscalar(value) && isequal(value, round(value)) && value > 0
    bool = true;
else
    bool = false;
end