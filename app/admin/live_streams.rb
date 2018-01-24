ActiveAdmin.register LiveStream do
	
	scope("Erroneous") {|scope| scope.where(id: (scope.drafted + scope.request_declined + scope.deleted_from_fb + scope.network_error).map(& :id))}
	controller do
    actions :all, :except => [:edit, :destroy]
  end
end
