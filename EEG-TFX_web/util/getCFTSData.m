function Data_Trans = getCFTSData(Data, CFTSInfo)
    % Data Format: Ch x N

    % Backup Data
    Data_Trans = Data;

    % C: Channel Selection
    Data_Trans = Data_Trans(CFTSInfo.SelCh, :);

    % F: Filtering
    Data_Trans = permute(filtfilt(CFTSInfo.Fb, CFTSInfo.Fa, permute(Data_Trans, [2 1])), [2 1]);

    % T: Time Window Selection
    Data_Trans = Data_Trans(:, CFTSInfo.TBand(1):CFTSInfo.TBand(2));


    windowFunction = str2func(CFTSInfo.WindowType);
 % Apply Window Function (if specified)
    if isfield(CFTSInfo, 'WindowType') && ~isempty(CFTSInfo.WindowType)

        % Generate the window
        window = windowFunction(size(Data_Trans, 2));

        % Expand the window to match the shape of Data_Trans
        window = repmat(window', size(Data_Trans, 1), 1);

        % Apply the window to each channel
        Data_Trans = Data_Trans .* window;
    end
end
