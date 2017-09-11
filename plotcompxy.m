function out = plotcompxy(data1,data2,fieldnamex,fieldnamey,infig)
% function out = plotcompxy(data1,data2,fieldnamex,fieldnamey,infig)
if nargin <5
    figure;
else
    figure(infig);
end;
    
cs = 'bgrcmkw';
axList = zeros(6,1);
maxYList = zeros(6,1);
minYList = zeros(6,1);
midXList = zeros(6,1);
rangeXList = zeros(6,1);
if size(data2.(fieldnamex),2)==1
    data2.(fieldnamex)=repmat(data2.(fieldnamex),1,6);
    data1.(fieldnamex)=repmat(data1.(fieldnamex),1,6);
end;
for musj = 1:size(data2.(fieldnamey),2)
    hold off;
    subplot(3,2,musj);
    plot(data1.(fieldnamex)(:,musj),data1.(fieldnamey)(:,musj),[cs(musj)],'linewidth',2);hold on;
    plot(data2.(fieldnamex)(:,musj),data2.(fieldnamey)(:,musj),[cs(musj),'-.'],'linewidth',2);
    yl = ylim;
    minYList(musj) = yl(1);
    maxYList(musj) = yl(2);
    xl = xlim;
    midXList(musj) = mean(xl);    
    rangeXList(musj) = xl(2)-xl(1);
    axList(musj) = gca;
    xlabel(fieldnamex);
    ylabel(fieldnamey);
    if isfield(data1,'sys');
        title(data1.sys.mnames(musj));
    end;
end;

xWidth = max(rangeXList);
%set yaxis to be scaled properly.
for musj =1:6
    subplot(3,2,musj);
    ylim([min(minYList),max(maxYList)]);
    xlim([midXList(musj)-xWidth/2,midXList(musj)+xWidth/2]);
end;

subplot(3,2,1);
legend('1','2');