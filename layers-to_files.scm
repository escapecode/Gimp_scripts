(define (ec-save-all-layers orig-image drawable
		directory
		image-format
		dont-ask
		rename?
		template
	)

	(define (save-layer orig-image layer name directory)
		(let ((buffer (car (gimp-edit-named-copy layer "temp-copy"))))
			(let ((image (car (gimp-edit-named-paste-as-new buffer))))
				(gimp-buffer-delete buffer)
				(set! buffer (strbreakup name "."))
				(unless (> (length buffer) 1)
					(set! name (string-append name "."))
					(set! name (string-append name image-format))
				)
				(when (and (not (= (car (gimp-image-base-type image)) INDEXED))
					(string-ci=? (car (last (strbreakup name "."))) "gif"))
					(gimp-image-convert-indexed image
						NO-DITHER
						MAKE-PALETTE
						255
						FALSE
						FALSE
						"" ))
				(gimp-file-save
					dont-ask
					image
					(car (gimp-image-get-active-layer image))
					(string-append directory "/" name)
					(string-append directory "/" name)
				)
				(gimp-image-delete image) ))
	)

	(let* (
			(layers nil)
			 (fullname "")
			 (basename "")
			 (layername "")
			 (format "")
			 (layerpos 1)
			 (framenum "")
			 (settings "")
			 (default-extension image-format)
			 (extension image-format)
			 (orig-selection 0)
		 )
		(gimp-image-undo-disable orig-image)
		(set! orig-selection (car (gimp-selection-save orig-image)))
		(gimp-selection-none orig-image)

		(set! extension (strbreakup template "."))
		(set! extension (if (> (length extension) 1)
			(car (last extension))
			default-extension))
		(when (= (string-length extension) 0)
			(set! default-extension image-format))
		(when (= rename? TRUE)
			(set! format (strbreakup template "#"))
			(if (> (length format) 1)
				(begin
					(set! basename (car format))
					(set! format (cdr format))
					(set! format (cons "" (butlast format)))
					(set! format (string-append "0" (unbreakupstr format "0"))) )
				(begin
					(set! basename (car (strbreakup template ".")))
					(set! format "0000") )))
		(set! layers (reverse (vector->list (cadr (gimp-image-get-layers orig-image)))))
		(while (pair? layers)
			(if (= rename? TRUE)
				(begin
					(set! framenum (number->string layerpos))
					(set! framenum (string-append
						(substring format 0 (- (string-length format)
							(string-length framenum))) framenum))
					(set! fullname (string-append basename framenum "." extension))
				)
				(begin
					(set! fullname (car (strbreakup
						 (car (gimp-drawable-get-name (car layers))) "(")))
					(gimp-drawable-set-name (car layers) fullname)
					(set! fullname (car (gimp-drawable-get-name (car layers))))
					(set! fullname(string-append (car (strbreakup fullname ".")) "." image-format))
				)
			)
			(save-layer orig-image (car layers) fullname directory)
			(set! layers (cdr layers))
			(set! layerpos (+ layerpos 1))
		)
		(gimp-selection-load orig-selection)
		(gimp-image-remove-channel orig-image orig-selection)
		(gimp-image-undo-enable orig-image)
		)
	)

(script-fu-register "ec-save-all-layers"
	"Save Layers as Images..."
	"Save each layer to a file."
	"Escapecode"
	"Escapecode"
	"05/26/2021"
	"*"
	SF-IMAGE		"Image"		0
	SF-DRAWABLE "Drawable" 0
	SF-DIRNAME "Directory to save images" ""
	SF-STRING "Image format" "jpg"
	SF-TOGGLE "Use default image save settings for each layer" TRUE
	SF-TOGGLE "Use following filename template, not layer name as filename" FALSE
	SF-STRING "	Filename Template (# is layer number digit)" "frame_##"
)

(script-fu-menu-register "ec-save-all-layers"
	 "<Image>/File/Save")
