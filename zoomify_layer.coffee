class ZoomifyLayer extends L.TileLayer
  '''Implement Zoomify layer for Cloudmade's Leaflet library'''
  
  constructor: (url, imageProperties, options={}) ->
    @options = options
    @baseUrl = url

    if not(imageProperties.width? and imageProperties.height?)
      throw('width and height must be defined')

    @imageProperties =
      width: imageProperties.width
      height: imageProperties.height
      tilesize: imageProperties.tilesize or 256
    @_initTiers()      
    # set minZoom and maxZoom
    @options.minZoom = 0
    @options.maxZoom = @numOfTiers() - 1


  _getTierForResolution: (resolution) ->
    lambda = (x, r) ->
      if r < resolution
        return lambda(x+1, r*2)
      return x
    return @numOfTiers() - lambda(0, 1) - 1


  _getSizeForTier: (tier) ->
    r = Math.pow(2, @numOfTiers() - tier - 1)
    return [Math.ceil(@imageProperties.width / r), Math.ceil(@imageProperties.height / r)]


  onAdd: (map) ->
    super map
    size = map.getSize()
    r = Math.max Math.ceil(@imageProperties.width / size.x), Math.ceil(@imageProperties.height / size.y)
    tier = @_getTierForResolution r

    layerSize = @_getSizeForTier tier
    offset = [(size.x - layerSize[0]) / 2, (size.y - layerSize[1]) / 2]
    window.ll = map.options.crs.pointToLatLng new L.Point(size.x / 2 - offset[0], size.y / 2 - offset[1]), tier
    map.setView ll, tier


  _createTile: ->
    # tile = @_tileImg.cloneNode(false);
    # tile = $('<img class="leaflet-tile">')[0]
    tile = document.createElement 'img'
    tile.setAttribute 'class', 'leaflet-tile'
    tile.onselectstart = tile.onmousemove = L.Util.falseFn;
    return tile;
  


  _tileShouldBeLoaded: (point) ->
    if point.x >= 0 and point.y >= 0
      tier = @_getZoomForUrl()
      if point.x <= @_tiers[tier][0] and point.y <= @_tiers[tier][1]
        console.log(point)
      return point.x <= @_tiers[tier][0] and point.y <= @_tiers[tier][1]
    return false

  _getTilePos: (tilePoint) ->
    origin = @_map.getPixelOrigin()
    return tilePoint.multiplyBy(@imageProperties.tilesize).subtract(origin);


  _getTileSize: ->
    @imageProperties.tilesize


  _initTiers: ->
    hf = (size, tilesize, k) ->
      if size % tilesize / Math.pow(2, k) < 1
        return Math.floor size / tilesize
      return Math.ceil size / tilesize

    @_tiers = []
    scaledTileSize = @imageProperties.tilesize / 2
    [i, x, y] = [-1, 3, 2]
    while Math.max(x, y) > 1
      i += 1
      scaledTileSize *= 2
      x = hf @imageProperties.width, scaledTileSize, i
      y = hf @imageProperties.height, scaledTileSize, i
      @_tiers.push [x - 1, y - 1, x * y]
    @_tiers.reverse()
    @_numOfTiers = i + 1


  numOfTiers: ->
    if not @_numOfTiers?
      i = 0
      a = Math.ceil(Math.max(@imageProperties.width, @imageProperties.height) / @imageProperties.tilesize)
      while a > 1
        i += 1
        a = Math.ceil a / 2
      @_numOfTiers = i + 1
      @_numOfTiers = i
    return @_numOfTiers


  _tileGroupNumber: (x, y, tier) ->
    numOfTiers = @numOfTiers()
    width = @imageProperties.width
    height = @imageProperties.height
    tileSize = @imageProperties.tilesize
    idx = 0
    for i in [0...tier]
      idx += @_tiers[i][2]
    idx += y * (@_tiers[tier][0] + 1) + x
    # idx += x
    return Math.floor idx / 256


  _getZoomForUrl: ->
    if @imageProperties?
      zoom = @_map.getZoom()
      return zoom
    return 0

  
  _adjustTilePoint: (tilePoint) ->
    tilePoint

  
  getTileUrl: (tilePoint, zoom) ->
    x = tilePoint.x
    y = tilePoint.y
    z = @_getZoomForUrl()
    tileGroup = @_tileGroupNumber x, y, z
    return @baseUrl + "TileGroup#{ tileGroup }/#{ z }-#{ x }-#{ y }.jpg" 


window.ZoomifyLayer = ZoomifyLayer