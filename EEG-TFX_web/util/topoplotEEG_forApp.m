function handle = topoplotEEG_forApp(Vl, loc_file, varargin)
% TOPOPLOTEEG - Modified for App Designer: support 'parent' axes
% Usage:
%   topoplotEEG(dataVector, 'channel_locations.txt', ..., 'parent', ax);

% ========= [MODIFICATION 1] Handle 'parent' parameter =========
ax = [];  % Default: current axes

% Extract 'parent' if provided in varargin
i = 1;
while i <= length(varargin)-1
    if ischar(varargin{i}) && strcmpi(varargin{i}, 'parent')
        ax = varargin{i+1};
        varargin(i:i+1) = [];  % Remove 'parent' pair
    else
        i = i + 2;
    end
end

if isempty(ax)
    ax = gca;
end

% Force future drawing to use this axes
cla(ax);
axes(ax);
hold(ax, 'on');

% ========= [ORIGINAL topoplotEEG CODE STARTS HERE] =========
% --- User Defined Defaults
MAXCHANS = 256;
DEFAULT_ELOC = 'eloc64.txt';
INTERPLIMITS = 'head';
MAPLIMITS = 'absmax';
GRID_SCALE = 67;
CONTOURNUM = 6;
STYLE = 'both';
HCOLOR = [0 0 0];
ECOLOR = [0 0 0];
CONTCOLOR = [0 0 0];
ELECTROD = 'on';
EMARKERSIZE = 6;
EFSIZE = get(0,'DefaultAxesFontSize');
HLINEWIDTH = 2;
EMARKER = '.';
SHADING = 'flat';

if nargin < 2
  loc_file = DEFAULT_ELOC;
end

if isempty(loc_file)
  loc_file = DEFAULT_ELOC;
end

% Handle parameter pairs
for i = 1:2:length(varargin)
    Param = lower(varargin{i});
    Value = varargin{i+1};
    switch Param
        case 'colormap', colormap(ax, Value);
        case {'interplimits','headlimits'}, INTERPLIMITS = lower(Value);
        case 'maplimits', MAPLIMITS = Value;
        case 'gridscale', GRID_SCALE = Value;
        case 'style', STYLE = lower(Value);
        case 'numcontour', CONTOURNUM = Value;
        case 'electrodes', ELECTROD = lower(Value);
        case 'emarker', EMARKER = Value;
        case {'headcolor','hcolor'}, HCOLOR = Value;
        case {'electcolor','ecolor'}, ECOLOR = Value;
        case {'emarkersize','emsize'}, EMARKERSIZE = Value;
        case {'efontsize','efsize'}, EFSIZE = Value;
        case 'shading', SHADING = lower(Value);
        otherwise, error(['Unknown parameter: ', Param]);
    end
end

% ===== Load electrode positions
fid = fopen(loc_file);
if fid < 1, error(['Cannot open electrode file: ', loc_file]); end
A = fscanf(fid,'%d %f %f %s',[7 MAXCHANS]);
fclose(fid);
A = A';

if length(Vl) ~= size(A,1)
    error('Data length does not match electrode file');
end
labels = setstr(A(:,4:7));
labels(labels=='.') = ' ';
Th = pi/180*A(:,2);
Rd = A(:,3);
ii = find(Rd <= 0.5);
Th = Th(ii);
Rd = Rd(ii);
Vl = Vl(ii);
labels = labels(ii,:);
[x, y] = pol2cart(Th, Rd);
rmax = 0.5;

% Interpolation Grid
if strcmp(INTERPLIMITS, 'head')
    xmin = min(-.5, min(x)); xmax = max(0.5, max(x));
    ymin = min(-.5, min(y)); ymax = max(0.5, max(y));
else
    xmin = max(-.5, min(x)); xmax = min(0.5, max(x));
    ymin = max(-.5, min(y)); ymax = min(0.5, max(y));
end

xi = linspace(xmin, xmax, GRID_SCALE);
yi = linspace(ymin, ymax, GRID_SCALE);
[Xi, Yi, Zi] = griddata(y, x, Vl, yi', xi, 'v4');

% Mask outside head
mask = sqrt(Xi.^2 + Yi.^2) <= rmax;
Zi(~mask) = NaN;

% Determine color limits
if ischar(MAPLIMITS)
    if strcmp(MAPLIMITS, 'absmax')
        clim = max(abs(Zi(:)));
        caxis(ax, [-clim clim]);
    elseif strcmp(MAPLIMITS, 'maxmin')
        caxis(ax, [min(Zi(:)) max(Zi(:))]);
    end
else
    caxis(ax, MAPLIMITS);
end

% Plot
delta = xi(2)-xi(1);
if strcmp(STYLE,'both') || strcmp(STYLE,'straight')
    surface(ax, Xi-delta/2, Yi-delta/2, zeros(size(Zi)), Zi, ...
        'EdgeColor','none','FaceColor',SHADING);
    if strcmp(STYLE,'both')
        contour(ax, Xi, Yi, Zi, CONTOURNUM, 'k');
    end
elseif strcmp(STYLE,'contour')
    contour(ax, Xi, Yi, Zi, CONTOURNUM, 'k');
elseif strcmp(STYLE,'fill')
    contourf(ax, Xi, Yi, Zi, CONTOURNUM, 'k');
end

% Set limits
set(ax,'XLim',[-rmax*1.3 rmax*1.3],'YLim',[-rmax*1.3 rmax*1.3])

% Draw Head, Ears, Nose
l = linspace(0,2*pi,100);
plot(ax, cos(l)*rmax, sin(l)*rmax, 'Color', HCOLOR, 'LineWidth', HLINEWIDTH);
plot(ax, [0.18*rmax, 0, -0.18*rmax], [rmax*0.9, rmax*1.15, rmax*0.9], 'Color', HCOLOR, 'LineWidth', HLINEWIDTH);
EarX = [.497 .510 .518 .5299 .5419 .54 .547 .532 .510 .489];
EarY = [.0555 .0775 .0783 .0746 .0555 -.0055 -.0932 -.1313 -.1384 -.1199];
plot(ax, EarX, EarY, 'Color', HCOLOR, 'LineWidth', HLINEWIDTH);
plot(ax, -EarX, EarY, 'Color', HCOLOR, 'LineWidth', HLINEWIDTH);

% Electrodes
if strcmp(ELECTROD, 'on')
    plot(ax, y, x, EMARKER, 'Color', ECOLOR, 'MarkerSize', EMARKERSIZE);
elseif strcmp(ELECTROD, 'labels')
    for i = 1:size(labels,1)
        text(ax, y(i), x(i), labels(i,:), 'HorizontalAlignment','center', 'VerticalAlignment','middle', 'Color',ECOLOR, 'FontSize', EFSIZE);
    end
elseif strcmp(ELECTROD, 'numbers')
    for i = 1:length(x)
        text(ax, y(i), x(i), num2str(i), 'HorizontalAlignment','center', 'VerticalAlignment','middle', 'Color',ECOLOR, 'FontSize', EFSIZE);
    end
end

axis(ax, 'off');
handle = ax;
end