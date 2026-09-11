"""
3D DenseNet Architecture for Volumetric Brain MRI Classification.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class _DenseLayer3D(nn.Module):
    def __init__(self, in_features, growth_rate, bn_size, drop_rate=0.0):
        super(_DenseLayer3D, self).__init__()
        self.drop_rate = drop_rate

        self.bn1 = nn.BatchNorm3d(in_features)
        self.relu1 = nn.ReLU(inplace=True)
        self.conv1 = nn.Conv3d(in_features, bn_size * growth_rate, kernel_size=1, stride=1, bias=False)

        self.bn2 = nn.BatchNorm3d(bn_size * growth_rate)
        self.relu2 = nn.ReLU(inplace=True)
        self.conv2 = nn.Conv3d(bn_size * growth_rate, growth_rate, kernel_size=3, stride=1, padding=1, bias=False)

    def forward(self, prev_features):
        out = torch.cat(prev_features, 1)
        out = self.conv1(self.relu1(self.bn1(out)))
        out = self.conv2(self.relu2(self.bn2(out)))
        if self.drop_rate > 0:
            out = F.dropout(out, p=self.drop_rate, training=self.training)
        return out


class _DenseBlock3D(nn.ModuleDict):
    def __init__(self, num_layers, in_features, bn_size, growth_rate, drop_rate=0.0):
        super(_DenseBlock3D, self).__init__()
        for i in range(num_layers):
            layer = _DenseLayer3D(
                in_features + i * growth_rate,
                growth_rate=growth_rate,
                bn_size=bn_size,
                drop_rate=drop_rate
            )
            self.add_module(f"denselayer{i + 1}", layer)

    def forward(self, init_features):
        features = [init_features]
        for name, layer in self.items():
            new_features = layer(features)
            features.append(new_features)
        return torch.cat(features, 1)


class _Transition3D(nn.Sequential):
    def __init__(self, in_features, out_features):
        super(_Transition3D, self).__init__()
        self.add_module("norm", nn.BatchNorm3d(in_features))
        self.add_module("relu", nn.ReLU(inplace=True))
        self.add_module("conv", nn.Conv3d(in_features, out_features, kernel_size=1, stride=1, bias=False))
        self.add_module("pool", nn.AvgPool3d(kernel_size=2, stride=2))


class DenseNet3D(nn.Module):
    def __init__(self, growth_rate=16, block_config=(4, 4, 4, 4), num_init_features=32,
                 bn_size=4, drop_rate=0.2, in_channels=1, num_classes=3):
        super(DenseNet3D, self).__init__()

        self.features = nn.Sequential()
        self.features.add_module("conv0", nn.Conv3d(in_channels, num_init_features, kernel_size=7, stride=2, padding=3, bias=False))
        self.features.add_module("norm0", nn.BatchNorm3d(num_init_features))
        self.features.add_module("relu0", nn.ReLU(inplace=True))
        self.features.add_module("pool0", nn.MaxPool3d(kernel_size=3, stride=2, padding=1))

        num_features = num_init_features
        for i, num_layers in enumerate(block_config):
            block = _DenseBlock3D(
                num_layers=num_layers,
                in_features=num_features,
                bn_size=bn_size,
                growth_rate=growth_rate,
                drop_rate=drop_rate
            )
            self.features.add_module(f"denseblock{i + 1}", block)
            num_features = num_features + num_layers * growth_rate
            if i != len(block_config) - 1:
                trans = _Transition3D(in_features=num_features, out_features=num_features // 2)
                self.features.add_module(f"transition{i + 1}", trans)
                num_features = num_features // 2

        self.features.add_module("norm_final", nn.BatchNorm3d(num_features))
        self.features.add_module("relu_final", nn.ReLU(inplace=True))

        self.avgpool = nn.AdaptiveAvgPool3d((1, 1, 1))
        self.classifier = nn.Linear(num_features, num_classes)

    def forward(self, x):
        features = self.features(x)
        out = self.avgpool(features)
        out = torch.flatten(out, 1)
        out = self.classifier(out)
        return out

    def get_target_layer_for_cam(self):
        """Returns the final dense block for Grad-CAM."""
        return self.features.denseblock4
