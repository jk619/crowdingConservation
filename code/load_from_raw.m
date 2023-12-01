function [bouma, area] = load_from_raw(surfaceType)



[datatable] = load_crowding('./data/crowdingData');
u_ses = unique(datatable.Session);
u_obs = unique(datatable.Observer);
bouma_sess = NaN(length(u_ses),length(u_obs));

for o = 1 : length(u_obs)

    for s = 1 : length(u_ses)

        sel = contains(datatable.Observer,u_obs{o}) & datatable.Session == s;
        bouma_factors = datatable.CrowdingDistance(sel) ./ datatable.RadialEccen(sel);
        bouma_sess(s,o) = geomean(bouma_factors);

    end
end

bouma = mean(bouma_sess);


%%
if ~exist('surfaceType', 'var') || isempty(surfaceType), surfaceType = 'midgray'; end

hemi = {'lh';'rh'};
researcher1 = load_surface('./data/surfaceData',surfaceType,'R1',hemi);
researcher2 = load_surface('./data/surfaceData',surfaceType,'R2',hemi);

r1 = sum(researcher1, 3); % sum across hemispheres
r2 = sum(researcher2, 3); % sum across hemispheres
area =  (r1+r2)/2; % average across researchers

bouma = bouma';
area = area';