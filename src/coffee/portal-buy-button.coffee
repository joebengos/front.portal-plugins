# DEPENDENCIES:
# jQuery

$ = window.jQuery

# CLASSES
class BuyButton
	constructor: (@element, @productId, buyData = {}, @options) ->
		@sku = buyData.sku || null
		@quantity = buyData.quantity || 1
		@seller = buyData.seller || 1
		@salesChannel = buyData.salesChannel || 1

		@accessories = []

		@init()

	init: =>
		@getChangesFromHREF()
		@bindEvents()
		@update()

	bindEvents: =>
		$(window).on 'vtex.sku.selected', @skuSelected
		$(window).on 'vtex.sku.unselected', @skuUnselected
		$(window).on 'vtex.quantity.ready', @quantityChanged
		$(window).on 'vtex.quantity.changed', @quantityChanged
		$(window).on 'vtex.accessories.updated', @accessoriesUpdated
		@element.on 'click', @buyButtonHandler

	check: (productId) =>
		productId == @productId

	getChangesFromHREF: =>
		href = @element.attr 'href'
		if @_url != href

			skuMatch = href.match(/sku=(.*?)&/)
			if skuMatch and skuMatch[1] and skuMatch[1] != @sku
				@sku = skuMatch[1]
				$(window).trigger 'vtex.sku.changed', [@productId, sku: @sku]

			qtyMatch = href.match(/qty=(.*?)&/)
			if qtyMatch and qtyMatch[1] and qtyMatch[1] != @quantity
				@quantity = qtyMatch[1]
				$(window).trigger 'vtex.quantity.changed', [@productId, @quantity]

			sellerMatch = href.match(/seller=(.*?)&/)
			if sellerMatch and sellerMatch[1] and sellerMatch[1] != @seller
				@seller = sellerMatch[1]

			salesChannelMatch = href.match(/sc=(.*?)&/)
			if salesChannelMatch and salesChannelMatch[1] and salesChannelMatch[1] != @salesChannel
				@salesChannel = salesChannelMatch[1]

		@_url = href

	skuSelected: (evt, productId, sku) =>
		return unless @check(productId)
		@getChangesFromHREF()
		@sku = sku.sku
		@update()

	skuUnselected: (evt, productId, selectableSkus) =>
		return unless @check(productId)
		@getChangesFromHREF()
		@sku = null
		@update()

	quantityChanged: (evt, productId, quantity) =>
		return unless @check(productId)
		@getChangesFromHREF()
		@quantity = quantity
		@update()

	accessoriesUpdated: (evt, productId, accessories) =>
		return unless @check(productId)
		@getChangesFromHREF()
		@accessories = accessories
		@update()

	getURL: =>
		url = "/checkout/cart/add?sku=#{@sku}&qty=#{@quantity}&seller=#{@seller}&sc=#{@salesChannel}&redirect=#{@options.redirect}"
		for acc in @accessories when acc.quantity > 0
			url += "&sku=#{acc.sku}&qty=#{acc.quantity}&seller=#{acc.sellerId}&sc=#{acc.salesChannel}"
		return url

	update: =>
		url = if @sku then @getURL() else "javascript:alert('#{@options.errorMessage}');"
		@element.attr('href', url)

	buyButtonHandler: (evt) =>
		return true if @redirect

		context.trigger 'vtex.modal.hide'
		$.get(@getURL())
		.done ->
			$(window).trigger 'vtex.cart.productAdded'
			$(window).trigger 'productAddedToCart'
		.fail ->
			@redirect = true
			window.location.href = @getURL()

		evt.preventDefault()
		return false


# PLUGIN ENTRY POINT
$.fn.buyButton = (productId, buyData, jsOptions) ->
	defaultOptions = $.extend true, {}, $.fn.buyButton.defaults
	for element in this
		$element = $(element)
		domOptions = $element.data()
		options = $.extend(true, defaultOptions, domOptions, jsOptions)
		unless $element.data('buyButton')
			$element.data('buyButton', new BuyButton($element, productId, buyData, options))

	return this


# PLUGIN DEFAULTS
$.fn.buyButton.defaults =
	errorMessage: "Por favor, selecione o modelo desejado."
	redirect: true
