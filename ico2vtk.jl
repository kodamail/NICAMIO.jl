using WriteVTK

points = rand(3, 5)

#cells = [MeshCell(VTKCellTypes.VTK_TRIANGLE, [1,4,2]), MeshCell(VTKCellTypes.VTK_QUAD, [2,4,3,5])]

cells = [MeshCell(VTKCellTypes.VTK_POLYGON, [1,4,2]), MeshCell(VTKCellTypes.VTK_POLYGON, [2,4,3,5])]


vtk_grid("test2", points, cells) do vtk
    vtk["temperature"] = rand(length(cells))
end
