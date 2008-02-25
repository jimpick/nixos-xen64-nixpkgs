args: with args;
rec {
  gstreamerFun = lib.sumArgs (selectVersion ./gstreamer "0.10.17") args;
  gstreamer = gstreamerFun null;

  gstPluginsBaseFun = lib.sumArgs (selectVersion ./gst-plugins-base "0.10.17")
    args { inherit gstreamer; };
  gstPluginsBase = gstPluginsBaseFun null;

  gstPluginsGoodFun = lib.sumArgs (selectVersion ./gst-plugins-good "0.10.6")
    args { inherit gstPluginsBase; };
  gstPluginsGood = gstPluginsGoodFun null;
}
