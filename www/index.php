<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Phalcon Vagrant</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
    <link href='//fonts.googleapis.com/css?family=Roboto' rel='stylesheet' type='text/css'>
    <style>
    body {
        padding-bottom: 20px;
        font-family: Roboto, arial, sans-serif;
    }

    @media (min-width: 768px) {
        .container {
            max-width: 730px;
        }
    }
    .header {
        background: #2a6496;
        padding-top: 20px;
    }
    .header h3 {
        padding-bottom: 12px;
        margin-top: 0;
        margin-bottom: 0;
        line-height: 40px;
        color: #fff;
    }
    .intro {
        padding: 15px;
        margin-bottom: 15px;
    }
    .intro p {
        margin-bottom: 0;
    }
    .btn-default, .btn-default:hover, .btn-default:focus, .btn-default:active, .btn-default.active, .open>.dropdown-toggle.btn-default {
        border: none !important;
    }
    .file-list {
        font-size: 16px;
    }
    .file-list a {
        padding: 2px 10px;
    }
    .file-list a:hover {
        background: #2a6496;
        color: #fff;
        text-decoration: none;
    }
    .file-list a.file {
        color: #7f8c8d;
    }
    .file-list a.file:hover {
        background: #7f8c8d;
        color: #fff;
    }
    </style>
</head>
<body>

    <div class="header">
        <div class="container">
            <div class="col-md-4">
                <h3 class="text-center">Phalcon Vagrant</h3>
            </div>
            <div class="col-md-8">
                <p class="text-center">
                    <a class="btn btn-md btn-default" target="_blank" href="http://phalconphp.com/en/" role="button"><span class="glyphicon glyphicon-home"></span> Phalcon Homepage</a>
                    <a class="btn btn-md btn-default" target="_blank" href="http://docs.phalconphp.com/en/latest/" role="button"><span class="glyphicon glyphicon-book"></span> Documentation</a>
                    <a class="btn btn-md btn-default" target="_blank" href="http://forum.phalconphp.com/" role="button"><span class="glyphicon glyphicon-comment"></span> Forums</a>
                </p>
            </div>
        </div>
    </div>

    <div class="intro"></div>

    <div class="container">
        <div class="row">
            <div class="col-md-12">
                <?php
                    $dir = new DirectoryIterator(dirname(__FILE__));
                    $types = [
                        'folder-close' => [],
                        'file'   => [],
                    ];

                    foreach ($dir as $fileinfo)
                    {
                        if ($fileinfo->isDot()) {
                            continue;
                        }

                        if (is_dir($fileinfo->getFilename())) {
                            $types['folder-close'][$fileinfo->getFilename()] = [$fileinfo->getOwner(), $fileinfo->getGroup(), $fileinfo->getPerms()];
                            
                            continue;
                        }
                        if ($fileinfo->getType = 'file') {
                            $types['file'][$fileinfo->getFilename()] = [$fileinfo->getOwner(), $fileinfo->getGroup(), $fileinfo->getPerms()];
                            continue;
                        }
                    }
                ?>
                <div class="panel panel-default">
                    <div class="panel-heading">Project manager</div>
                    <div class="panel-body" style="background-color:#f9fbfb">
                        <p>
                            To add a VirtualHosts, checkout the <code>README.md</code> file. Projects go in <code>www/&lt;project-name&gt;/</code>
                        </p>
                    </div>

                    <table class="table">
                        <thead>
                            <tr>
                                <th>File name</th>
                                <th>Owner</th>
                                <th>Group</th>
                                <th>Permissions</th>
                            </tr>
                        </thead>
                        <tbody class="file-list">
                            <?php foreach ($types as $type => $content): ?>
                                <?php ksort($content); ?>
                                <?php foreach ($content as $name => $options): ?>
                                    <tr>
                                        <td>
                                            <a class="<?php echo $type ?>" href="<?php echo $name ?>">
                                                <span class="glyphicon glyphicon glyphicon-<?php echo $type ?>"></span>
                                                <?php echo $name ?>
                                            </a>
                                        </td>
                                        <?php
                                            list($owner, $group, $perms) = $options;
                                            $owner = posix_getpwuid($owner);
                                            $group = posix_getgrgid($group);
                                        ?>
                                        <td>
                                            <?php echo $owner['name'] ?>
                                        </td>
                                        <td>
                                            <?php echo $group['name']; ?>
                                        </td>
                                        <td>
                                            <?php echo substr(sprintf('%o', $perms), -4); ?>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

</body>
</html>
