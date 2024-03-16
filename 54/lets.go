package main

import (
	"bufio"
	"image"
	"image/color"
	"image/png"
	"io"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"
	"sync"
)

type Vector = [3]float64

func scale(v Vector, scalar float64) Vector {
	for i := range v {
		v[i] *= scalar
	}
	return v
}

func add(v, w Vector) Vector {
	for i := range v {
		v[i] += w[i]
	}
	return v
}

func sub(v, w Vector) Vector {
	return add(v, scale(w, -1))
}

func dot(v, w Vector) (sum float64) {
	for i := range v {
		sum += v[i] * w[i]
	}
	return
}

func cross(v, w Vector) Vector {
	return Vector{
		v[1]*w[2] - v[2]*w[1],
		v[2]*w[0] - v[0]*w[2],
		v[0]*w[1] - v[1]*w[0],
	}
}

type Triangle = [3]Vector

type KdNode struct {
	pivotValue  float64
	pivotAxis   uint8
	left, right KdTree
}

func (node *KdNode) addTriangleIndices(ray Ray, indices map[int]struct{}) {
	delta := node.pivotValue - ray.origin[node.pivotAxis]
	if delta > 0 && ray.direction[node.pivotAxis] <= 0 {
		node.left.addTriangleIndices(ray, indices)
	} else if delta < 0 && ray.direction[node.pivotAxis] >= 0 {
		node.right.addTriangleIndices(ray, indices)
	} else {
		node.left.addTriangleIndices(ray, indices)
		node.right.addTriangleIndices(ray, indices)
	}
}

type KdLeaf struct {
	triangleIndices []int
}

func (leaf *KdLeaf) addTriangleIndices(ray Ray, indices map[int]struct{}) {
	for _, i := range leaf.triangleIndices {
		indices[i] = struct{}{}
	}
}

type KdTree interface {
	addTriangleIndices(ray Ray, indices map[int]struct{})
}

func buildKdTree(tris []Triangle, indices []int, axis uint8) KdTree {
	if len(indices) <= 32 {
		return &KdLeaf{indices}
	}
	coords := make([]float64, 0, 3*len(indices))
	for _, i := range indices {
		for _, p := range tris[i] {
			coords = append(coords, p[axis])
		}
	}
	sort.Float64s(coords)
	pivotValue := coords[len(coords)/2]
	var leftIndices, rightIndices []int
	for _, i := range indices {
		left, right := false, false
		for _, p := range tris[i] {
			left = left || p[axis] <= pivotValue
			right = right || p[axis] >= pivotValue
		}
		if left {
			leftIndices = append(leftIndices, i)
		}
		if right {
			rightIndices = append(rightIndices, i)
		}
	}
	if len(leftIndices) == len(rightIndices) {
		return &KdLeaf{indices}
	}
	nextAxis := (axis + 1) % 3
	return &KdNode{
		pivotValue, axis,
		buildKdTree(tris, leftIndices, nextAxis),
		buildKdTree(tris, rightIndices, nextAxis),
	}
}

type Model struct {
	texture image.Image
	mesh    []Triangle
	idx     KdTree
	uvs     [][3][2]float64
}

type Scene = Model

func readScene(png io.Reader, obj io.Reader) Scene {
	texture, _, err := image.Decode(png)
	if err != nil {
		panic(err)
	}
	var v [][3]float64
	var vt [][2]float64
	var f [][3][2]int
	scanner := bufio.NewScanner(obj)
	for scanner.Scan() {
		words := strings.Split(scanner.Text(), " ")
		float := func(i int) float64 {
			f, err := strconv.ParseFloat(words[i], 64)
			if err != nil {
				panic(err)
			}
			return f
		}
		atoidx := func(s string) int {
			k, err := strconv.Atoi(s)
			if err != nil {
				panic(err)
			}
			return k - 1
		}
		indices := func(i int) [2]int {
			parts := strings.Split(words[i], "/")
			switch len(parts) {
			case 1:
				j := atoidx(parts[0])
				return [2]int{j, j}
			case 2:
				return [2]int{atoidx(parts[0]), atoidx(parts[1])}
			default:
				panic("unsupported index format")
			}
		}
		switch words[0] {
		case "v":
			if len(words) > 4 {
				panic("too many vertex coordinates")
			}
			v = append(v, [3]float64{float(1), float(2), float(3)})
		case "vt":
			if len(words) > 3 {
				panic("too many texture coordinates")
			}
			vt = append(vt, [2]float64{float(1), 1 - float(2)})
		case "f":
			f = append(f, [3][2]int{indices(1), indices(2), indices(3)})
		case "#":
		default:
			panic("unsupported obj command")
		}
	}
	var mesh []Triangle
	var uvs [][3][2]float64
	for _, face := range f {
		var tri Triangle
		var uv [3][2]float64
		for i := range face {
			tri[i] = v[face[i][0]]
			uv[i] = vt[face[i][1]]
		}
		mesh = append(mesh, tri)
		uvs = append(uvs, uv)
	}
	indices := make([]int, 0, len(mesh))
	for i := range mesh {
		indices = append(indices, i)
	}
	return Scene{texture, mesh, buildKdTree(mesh, indices, 0), uvs}
}

type Ray struct {
	origin, direction Vector
}

type RayTriangleIntersection struct {
	t, u, v float64
}

// Möller-Trumbore line-triangle intersection algorithm
func (ray Ray) intersect(tri Triangle) (intersects bool, intersection RayTriangleIntersection) {
	const epsilon = 1e-7
	e1, e2 := sub(tri[1], tri[0]), sub(tri[2], tri[0])
	dir_cross_e2 := cross(ray.direction, e2)
	det := dot(e1, dir_cross_e2)
	if math.Abs(det) < epsilon {
		return
	}
	rel_origin := sub(ray.origin, tri[0])
	intersection.u = dot(rel_origin, dir_cross_e2) / det
	if intersection.u < 0 || intersection.u > 1 {
		return
	}
	rel_origin_cross_e1 := cross(rel_origin, e1)
	intersection.v = dot(ray.direction, rel_origin_cross_e1) / det
	if intersection.v < 0 || intersection.u+intersection.v > 1 {
		return
	}
	intersection.t = dot(e2, rel_origin_cross_e1) / det
	if intersection.t <= epsilon {
		return
	}
	intersects = true
	return
}

type Intersection struct {
	triangleIndex int
	t, u, v       float64
}

func (scene Scene) cast(ray Ray) color.Color {
	intersections := []Intersection{}
	triIndices := map[int]struct{}{}
	scene.idx.addTriangleIndices(ray, triIndices)
	for i := range triIndices {
		tri := scene.mesh[i]
		intersects, p := ray.intersect(tri)
		if intersects {
			intersections = append(intersections, Intersection{i, p.t, p.u, p.v})
		}
	}
	sort.Slice(intersections, func(i, j int) bool {
		return intersections[i].t > intersections[j].t
	})
	bounds := scene.texture.Bounds()
	if scene.texture.ColorModel() != color.NRGBAModel {
		panic("unsupported color model")
	}
	w, h := bounds.Max.X-bounds.Min.X, bounds.Max.Y-bounds.Min.Y
	var rr, rb, rg, ra float64
	for _, intersection := range intersections {
		uvs := scene.uvs[intersection.triangleIndex]
		u, v := intersection.u, intersection.v
		ax, ay := uvs[0][0], uvs[0][1]
		ux, uy := uvs[1][0]-ax, uvs[1][1]-ay
		vx, vy := uvs[2][0]-ax, uvs[2][1]-ay
		tx, ty := ax+u*ux+v*vx, ay+u*uy+v*vy
		color := scene.texture.At(bounds.Min.X+int(math.Floor(float64(w)*tx)), bounds.Min.Y+int(math.Floor(float64(h)*ty)))
		r, g, b, a := color.RGBA()
		if a == 0 {
			continue
		}
		fa := float64(a) / 0xFFFF
		linearize := func(c uint32) float64 {
			return math.Pow(float64(c)/0xFFFF/fa, 2.2)
		}
		fr, fg, fb, fa := linearize(r), linearize(g), linearize(b), float64(a)/0xFFFF
		blended_a := fa + ra*(1-fa)
		blend := func(rc, fc float64) float64 {
			return ((1-fa)*ra*rc + fa*fc) / blended_a
		}
		rr, rg, rb, ra = blend(rr, fr), blend(rg, fg), blend(rb, fb), blended_a
	}
	delinearize := func(c float64) uint8 {
		return uint8(math.Floor(math.Pow(c, 1.0/2.2)*0xFF + 0.5))
	}
	return color.RGBA{delinearize(rr), delinearize(rg), delinearize(rb), uint8(math.Floor(ra*0xFF + 0.5))}
}

func (scene Scene) render() image.Image {
	d := 256
	res := image.NewRGBA(image.Rect(0, 0, d, d))
	var wg sync.WaitGroup
	var mutex sync.Mutex
	for y := 0; y < d; y++ {
		y := y
		wg.Add(1)
		go (func() {
			defer wg.Done()
			for x := 0; x < d; x++ {
				// isometric projection (parallel rays)
				color := scene.cast(Ray{Vector{float64(x-d/2) / 1000, float64(d-y-1) / 1000, 10}, Vector{0, 0, -1}})
				mutex.Lock()
				res.Set(x, y, color)
				mutex.Unlock()
			}

		})()
	}
	wg.Wait()
	return res
}

func main() {
	// bnuuy.png is "CC0 2018 KickAir8P - Public Domain", see https://web.archive.org/web/20240315223118/https://blenderartists.org/t/uv-unwrapped-stanford-bunny-happy-spring-equinox/1101297
	pngReader, err := os.Open("bnuuy.png")
	if err != nil {
		panic(err)
	}
	defer pngReader.Close()
	objReader, err := os.Open("bnuuy.obj")
	if err != nil {
		panic(err)
	}
	defer objReader.Close()
	scene := readScene(pngReader, objReader)

	file, err := os.Create("a.png")
	if err != nil {
		panic(err)
	}
	err = png.Encode(file, scene.render())
	if err != nil {
		panic(err)
	}
}
