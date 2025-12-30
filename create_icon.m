% Create TOML Toolbox Icon
% Generates a 256x256 pixel icon with a document/config file theme

% Create figure
fig = figure('Position', [100 100 256 256], 'Color', 'w', 'MenuBar', 'none', 'ToolBar', 'none');
ax = axes('Position', [0 0 1 1], 'XLim', [0 256], 'YLim', [0 256]);
axis off;
hold on;

% Background gradient (light blue to white)
for i = 1:256
    y = 256 - i;
    color = [0.9 + 0.1*(i/256), 0.95 + 0.05*(i/256), 1];
    rectangle('Position', [0 y 256 1], 'FaceColor', color, 'EdgeColor', 'none');
end

% Document/file shape
docColor = [0.95 0.95 0.98];  % Light gray-blue
docX = [60, 196, 196, 176, 176, 60, 60];
docY = [40, 40, 216, 216, 196, 196, 40];
fill(docX, docY, docColor, 'EdgeColor', [0.3 0.3 0.4], 'LineWidth', 2);

% Folded corner
cornerX = [176, 196, 176, 176];
cornerY = [216, 216, 196, 216];
fill(cornerX, cornerY, [0.85 0.85 0.9], 'EdgeColor', [0.3 0.3 0.4], 'LineWidth', 2);

% Add horizontal lines to represent text/config entries
lineColor = [0.4 0.5 0.7];
lineY = [180, 155, 130, 105, 80];
for y = lineY
    line([80 176], [y y], 'Color', lineColor, 'LineWidth', 2);
end

% Add key-value pair dots
dotColor = [0.2 0.4 0.6];
for y = lineY
    scatter(85, y, 30, dotColor, 'filled');
end

% Add "TOML" text
text(128, 50, 'TOML', 'FontSize', 48, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Color', [0.1 0.3 0.5], ...
    'FontName', 'Arial');

% Add small "config" text
text(128, 25, 'config', 'FontSize', 14, 'FontWeight', 'normal', ...
    'HorizontalAlignment', 'center', 'Color', [0.4 0.5 0.6], ...
    'FontName', 'Arial', 'FontAngle', 'italic');

% Capture and save
frame = getframe(fig);
img = frame.cdata;

% Save as PNG
imwrite(img, 'toolbox/toml_icon.png');

% Also create a smaller 128x128 version
img_small = imresize(img, [128 128]);
imwrite(img_small, 'toolbox/toml_icon_128.png');

close(fig);

disp('Icon created successfully!');
disp('  - toolbox/toml_icon.png (256x256)');
disp('  - toolbox/toml_icon_128.png (128x128)');
