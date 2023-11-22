init:
	echo "n" | npx create-next-app prototype --ts --eslint --experimental-app --src-dir --use-npm --no-tailwind --app

ssg:
	sed -i '' 's/"build": "next build"/"build": "next build \&\& next export"/' prototype/package.json

