function FScore = F_Score(x, y, ~)
%   opt.ExecuteMode = 'for';
    yn = unique(y);
%     if isempty(gcp('nocreate'))
%     parpool; % 启动并行池
%     end
%     
    [~, FeaNum] = size(x);
    FScore = zeros(FeaNum,1);
    for i = 1:FeaNum
            xi = x(:,i);
            mxi = mean(xi);
            xi_pos = xi(y==yn(1));
            xi_neg = xi(y==yn(2));
            mxi_pos = mean(xi_pos);
            mxi_neg = mean(xi_neg);
            vxi_pos = var(xi_pos);
            vxi_neg = var(xi_neg);
        
            FScore(i) = ((mxi_pos-mxi_neg)^2+(mxi_neg-mxi_pos)^2)/(vxi_pos+vxi_neg);
%     if isequal(opt.ExecuteMode, 'parfor')
%         parfor i = 1:FeaNum
%             xi = x(:,i);
%             mxi = mean(xi);
%             xi_pos = xi(y==yn(1));
%             xi_neg = xi(y==yn(2));
%             mxi_pos = mean(xi_pos);
%             mxi_neg = mean(xi_neg);
%             vxi_pos = var(xi_pos);
%             vxi_neg = var(xi_neg);
%         
%             FScore(i) = ((mxi_pos-mxi_neg)^2+(mxi_neg-mxi_pos)^2)/(vxi_pos+vxi_neg);
%         
%         end
%     else
%         for i = 1:FeaNum
%             xi = x(:,i);
%             mxi = mean(xi);
%             xi_pos = xi(y==yn(1));
%             xi_neg = xi(y==yn(2));
%             mxi_pos = mean(xi_pos);
%             mxi_neg = mean(xi_neg);
%             vxi_pos = var(xi_pos);
%             vxi_neg = var(xi_neg);
%         
%             FScore(i) = ((mxi_pos-mxi_neg)^2+(mxi_neg-mxi_pos)^2)/(vxi_pos+vxi_neg);
%         
%         end
    end
end

%原来运行不出来地形图，但特征曲线正常的
% function FScore = FScoreFuncG1(x, y, opt)
%    opt.ExecuteMode = 'for';
%     yn = unique(y);
%     
%     [~, FeaNum] = size(x);
%     FScore = zeros(FeaNum,1);
%     if isequal(opt.ExecuteMode, 'parfor')
%         parfor i = 1:FeaNum
%             xi = x(:,i);
%             mxi = mean(xi);
%             xi_pos = xi(y==yn(1));
%             xi_neg = xi(y==yn(2));
%             mxi_pos = mean(xi_pos);
%             mxi_neg = mean(xi_neg);
%             vxi_pos = var(xi_pos);
%             vxi_neg = var(xi_neg);
%         
%             FScore(i) = ((mxi_pos-mxi_neg)^2+(mxi_neg-mxi_pos)^2)/(vxi_pos+vxi_neg);
%         
%         end
%     else
%         for i = 1:FeaNum
%             xi = x(:,i);
%             mxi = mean(xi);
%             xi_pos = xi(y==yn(1));
%             xi_neg = xi(y==yn(2));
%             mxi_pos = mean(xi_pos);
%             mxi_neg = mean(xi_neg);
%             vxi_pos = var(xi_pos);
%             vxi_neg = var(xi_neg);
%         
%             FScore(i) = ((mxi_pos-mxi_neg)^2+(mxi_neg-mxi_pos)^2)/(vxi_pos+vxi_neg);
%         
%         end
%     end
% end
